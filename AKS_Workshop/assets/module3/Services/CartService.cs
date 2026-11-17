using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using CaldovaBakery.Data;
using CaldovaBakery.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace CaldovaBakery.Services
{
    public class CartService
    {
        private readonly IHttpContextAccessor accessor;
        private readonly BakeryContext database;
        private ISession Session => accessor.HttpContext.Session;

        public CartService(IHttpContextAccessor accessor, BakeryContext database)
        {
            this.accessor = accessor;
            this.database = database;
        }

        private List<CartItem> Read() => JsonSerializer.Deserialize<List<CartItem>>(Session.GetString("Cart") ?? "[]");
        private void Write(List<CartItem> items) => Session.SetString("Cart", JsonSerializer.Serialize(items));

        public async Task<CartViewModel> GetAsync()
        {
            var items = Read();
            var identifiers = items.Select(item => item.ProductID).ToList();
            var products = await database.Products.AsNoTracking().Where(product => identifiers.Contains(product.ID)).ToListAsync();
            var validItems = items.Where(item => products.Any(product => product.ID == item.ProductID)).ToList();
            if (validItems.Count != items.Count) Write(validItems);
            return new CartViewModel
            {
                Lines = validItems.Select(item => new CartLine
                {
                    Product = products.Single(product => product.ID == item.ProductID),
                    Quantity = item.Quantity
                }).ToList()
            };
        }

        public bool SetQuantity(int productID, int quantity, bool add = false)
        {
            var items = Read();
            var item = items.SingleOrDefault(entry => entry.ProductID == productID);
            var nextQuantity = quantity + (add ? item?.Quantity ?? 0 : 0);
            if (quantity < 0 || nextQuantity < 0 || nextQuantity > 99) return false;
            if (nextQuantity == 0) items.RemoveAll(entry => entry.ProductID == productID);
            else if (item == null) items.Add(new CartItem { ProductID = productID, Quantity = nextQuantity });
            else item.Quantity = nextQuantity;
            Write(items);
            return true;
        }

        public void Clear() => Session.Remove("Cart");
    }
}