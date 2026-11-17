using System.Threading.Tasks;
using CaldovaBakery.Data;
using CaldovaBakery.Services;
using Microsoft.AspNetCore.Mvc;

namespace CaldovaBakery.Controllers
{
    public class CartController : Controller
    {
        private readonly CartService cart;
        private readonly BakeryContext database;
        public CartController(CartService cart, BakeryContext database)
        {
            this.cart = cart;
            this.database = database;
        }

        public async Task<IActionResult> Index() => View(await cart.GetAsync());

        [HttpPost]
        public async Task<IActionResult> Add(int id, int quantity = 1)
        {
            if (!ModelState.IsValid || quantity < 1 || quantity > 99) return BadRequest();
            if (await database.Products.FindAsync(id) == null) return NotFound();
            if (!cart.SetQuantity(id, quantity, true)) TempData["Error"] = "You can order up to 99 of each product.";
            else TempData["Success"] = "Added to your basket.";
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        public IActionResult Update(int id, int quantity)
        {
            if (!ModelState.IsValid || !cart.SetQuantity(id, quantity)) return BadRequest();
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        public IActionResult Remove(int id)
        {
            cart.SetQuantity(id, 0);
            return RedirectToAction(nameof(Index));
        }
    }
}