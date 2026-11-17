using System.Linq;
using System.Threading.Tasks;
using CaldovaBakery.Data;
using CaldovaBakery.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CaldovaBakery.Controllers
{
    public class ProductsController : Controller
    {
        private readonly BakeryContext database;
        public ProductsController(BakeryContext database) => this.database = database;

        public async Task<IActionResult> Index(string search, string category)
        {
            var products = database.Products.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search)) products = products.Where(product => product.Name.Contains(search) || product.Description.Contains(search));
            if (!string.IsNullOrWhiteSpace(category)) products = products.Where(product => product.Category == category);
            return View(new CatalogViewModel
            {
                Products = await products.OrderBy(product => product.Name).ToListAsync(),
                Categories = await database.Products.Select(product => product.Category).Distinct().OrderBy(value => value).ToListAsync(),
                Search = search,
                Category = category
            });
        }

        public async Task<IActionResult> Details(int id)
        {
            var product = await database.Products.AsNoTracking().SingleOrDefaultAsync(entry => entry.ID == id);
            if (product == null) return NotFound();
            return View(product);
        }
    }
}