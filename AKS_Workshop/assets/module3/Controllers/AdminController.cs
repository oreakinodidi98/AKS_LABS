using System.Linq;
using System.Threading.Tasks;
using CaldovaBakery.Data;
using CaldovaBakery.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CaldovaBakery.Controllers
{
    public class AdminController : Controller
    {
        private readonly BakeryContext database;
        public AdminController(BakeryContext database) => this.database = database;
        public async Task<IActionResult> Index() => View(await database.Products.AsNoTracking().OrderBy(product => product.Name).ToListAsync());
        public IActionResult Create() => View(new Product { Image = "/images/croissant.jpg" });

        [HttpPost]
        public async Task<IActionResult> Create([Bind("Name,Price,Image,Description,Category")] Product product)
        {
            if (!ModelState.IsValid) return View(product);
            database.Products.Add(product);
            await database.SaveChangesAsync();
            TempData["Success"] = "Product added to the bakery.";
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Edit(int id)
        {
            var product = await database.Products.FindAsync(id);
            if (product == null) return NotFound();
            return View(product);
        }

        [HttpPost]
        public async Task<IActionResult> Edit(int id, [Bind("ID,Name,Price,Image,Description,Category")] Product input)
        {
            if (id != input.ID) return BadRequest();
            if (!ModelState.IsValid) return View(input);
            var product = await database.Products.FindAsync(id);
            if (product == null) return NotFound();
            product.Name = input.Name;
            product.Price = input.Price;
            product.Image = input.Image;
            product.Description = input.Description;
            product.Category = input.Category;
            await database.SaveChangesAsync();
            TempData["Success"] = "Product updated.";
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Delete(int id)
        {
            var product = await database.Products.AsNoTracking().SingleOrDefaultAsync(entry => entry.ID == id);
            if (product == null) return NotFound();
            return View(product);
        }

        [HttpPost, ActionName("Delete")]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var product = await database.Products.FindAsync(id);
            if (product == null) return NotFound();
            database.Products.Remove(product);
            await database.SaveChangesAsync();
            TempData["Success"] = "Product deleted. Existing orders are unchanged.";
            return RedirectToAction(nameof(Index));
        }
    }
}