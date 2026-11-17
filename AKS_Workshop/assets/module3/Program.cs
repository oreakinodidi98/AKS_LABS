using System.Threading.Tasks;
using CaldovaBakery.Data;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace CaldovaBakery
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var host = Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(builder => builder.UseStartup<Startup>())
                .Build();
            using (var scope = host.Services.CreateScope())
            {
                await SeedData.InitializeAsync(scope.ServiceProvider.GetRequiredService<BakeryContext>());
            }
            await host.RunAsync();
        }
    }
}