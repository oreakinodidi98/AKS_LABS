using System;
using System.Globalization;
using CaldovaBakery.Data;
using CaldovaBakery.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace CaldovaBakery
{
    public class Startup
    {
        private readonly IConfiguration configuration;
        public Startup(IConfiguration configuration) => this.configuration = configuration;

        public void ConfigureServices(IServiceCollection services)
        {
            var provider = configuration["DatabaseProvider"] ?? "Sqlite";
            if (string.Equals(provider, "Sqlite", StringComparison.OrdinalIgnoreCase))
            {
                var connection = configuration.GetConnectionString("SqliteDatabase") ?? "Data Source=caldova-bakery.db";
                services.AddDbContext<BakeryContext>(options => options.UseSqlite(connection));
            }
            else if (string.Equals(provider, "SqlServer", StringComparison.OrdinalIgnoreCase))
            {
                var connection = configuration.GetConnectionString("BakeryDatabase");
                if (string.IsNullOrWhiteSpace(connection))
                    throw new InvalidOperationException("Set ConnectionStrings__BakeryDatabase to a SQL Server connection string. See README.md.");
                services.AddDbContext<BakeryContext>(options => options.UseSqlServer(connection, sql => sql.EnableRetryOnFailure()));
            }
            else
            {
                throw new InvalidOperationException("DatabaseProvider must be Sqlite or SqlServer. See README.md.");
            }
            services.AddDistributedMemoryCache();
            services.AddSession(options =>
            {
                options.IdleTimeout = TimeSpan.FromMinutes(60);
                options.Cookie.HttpOnly = true;
                options.Cookie.IsEssential = true;
                options.Cookie.SameSite = SameSiteMode.Lax;
            });
            services.AddHttpContextAccessor();
            services.AddScoped<CartService>();
            services.AddControllersWithViews(options => options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()));
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment environment)
        {
            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.GetCultureInfo("en-US");
            CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.GetCultureInfo("en-US");
            if (environment.IsDevelopment()) app.UseDeveloperExceptionPage();
            else app.UseExceptionHandler("/Home/Error");
            app.UseStaticFiles();
            app.UseRouting();
            app.UseSession();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapGet("/health", context => context.Response.WriteAsync("Healthy"));
                endpoints.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}");
            });
        }
    }
}