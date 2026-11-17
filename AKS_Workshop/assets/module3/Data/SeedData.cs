using System.Threading.Tasks;
using CaldovaBakery.Models;
using Microsoft.EntityFrameworkCore;

namespace CaldovaBakery.Data
{
    public static class SeedData
    {
        public static async Task InitializeAsync(BakeryContext database)
        {
            await database.Database.EnsureCreatedAsync();
            if (await database.Products.AnyAsync()) return;
            database.Products.AddRange(
                new Product { Name = "Butter croissant", Price = 4.50m, Category = "Pastries", Image = "/images/croissant.jpg", Description = "Golden, shatteringly crisp layers folded with cultured butter. A little everyday luxury." },
                new Product { Name = "Country sourdough", Price = 8.00m, Category = "Bread", Image = "/images/sourdough.jpg", Description = "Our slow-fermented signature loaf, with a caramelized crust and a soft, open crumb." },
                new Product { Name = "Strawberry celebration cake", Price = 32.00m, Category = "Cakes", Image = "/images/cake.jpg", Description = "Vanilla sponge, whipped cream and strawberries. Made for sharing, serves six." },
                new Product { Name = "Chocolate chip cookie", Price = 3.50m, Category = "Cookies", Image = "/images/cookie.jpg", Description = "Crisp edges, a soft center and generous pockets of dark chocolate. Finished with sea salt." },
                new Product { Name = "Cinnamon morning bun", Price = 5.00m, Category = "Pastries", Image = "/images/bun.jpg", Description = "Soft swirls of cinnamon sugar, baked until golden and finished with vanilla icing." },
                new Product { Name = "Blueberry muffin", Price = 4.00m, Category = "Pastries", Image = "/images/muffin.jpg", Description = "A tender, buttery muffin packed with blueberries and topped with a delicate crumble." });
            await database.SaveChangesAsync();
        }
    }
}