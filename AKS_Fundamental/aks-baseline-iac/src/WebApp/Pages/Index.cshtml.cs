using Microsoft.AspNetCore.Mvc.RazorPages;
using WebApp.Models;
using System.Net.Http.Json;

namespace WebApp.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    public List<Product> Products { get; set; } = new();
    public string ApiBaseUrl { get; set; } = string.Empty;

    public IndexModel(
        ILogger<IndexModel> logger,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration)
    {
        _logger = logger;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    public async Task OnGetAsync()
    {
        ApiBaseUrl = _configuration["ApiSettings:BaseUrl"] ?? "http://localhost:5000";
        
        try
        {
            var client = _httpClientFactory.CreateClient("ProductsApi");
            var products = await client.GetFromJsonAsync<List<Product>>("api/products");
            
            if (products != null)
            {
                Products = products;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching products from API");
        }
    }
}
