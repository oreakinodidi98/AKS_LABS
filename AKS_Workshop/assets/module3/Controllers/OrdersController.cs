using System.Linq;
using System.Threading.Tasks;
using CaldovaBakery.Data;
using CaldovaBakery.Models;
using CaldovaBakery.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CaldovaBakery.Controllers
{
    public class OrdersController : Controller
    {
        private readonly BakeryContext database;
        private readonly CartService cart;
        public OrdersController(BakeryContext database, CartService cart)
        {
            this.database = database;
            this.cart = cart;
        }

        public async Task<IActionResult> Checkout()
        {
            var basket = await cart.GetAsync();
            if (basket.Lines.Count == 0) return RedirectToAction("Index", "Cart");
            return View(new CheckoutViewModel { Cart = basket });
        }

        [HttpPost]
        public async Task<IActionResult> Checkout([Bind("CustomerName,Email,Notes")] CheckoutViewModel input)
        {
            input.Cart = await cart.GetAsync();
            if (input.Cart.Lines.Count == 0) return RedirectToAction("Index", "Cart");
            if (!ModelState.IsValid) return View(input);
            var order = new Order
            {
                CustomerName = input.CustomerName,
                Email = input.Email,
                Notes = input.Notes,
                Items = input.Cart.Lines.Select(line => new OrderItem
                {
                    ProductName = line.Product.Name,
                    UnitPrice = line.Product.Price,
                    Quantity = line.Quantity
                }).ToList()
            };
            database.Orders.Add(order);
            await database.SaveChangesAsync();
            HttpContext.Session.SetInt32("LastOrder", order.ID);
            cart.Clear();
            return RedirectToAction(nameof(Summary));
        }

        public async Task<IActionResult> Summary()
        {
            var id = HttpContext.Session.GetInt32("LastOrder");
            if (!id.HasValue) return RedirectToAction("Index", "Products");
            var order = await database.Orders.AsNoTracking().Include(entry => entry.Items).SingleOrDefaultAsync(entry => entry.ID == id.Value);
            if (order == null) return NotFound();
            return View(order);
        }
    }
}