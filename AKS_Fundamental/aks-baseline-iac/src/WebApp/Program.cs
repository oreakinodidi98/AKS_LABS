var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddHttpClient("ProductsApi", client =>
{
    var baseUrl = builder.Configuration["ApiSettings:BaseUrl"] ?? "http://localhost:5000";
    client.BaseAddress = new Uri(baseUrl);
});

// Add health checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();
app.MapRazorPages();

// Health endpoints
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");

app.Run();
