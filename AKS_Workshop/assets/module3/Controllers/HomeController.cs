using System.Linq;
using System.Threading.Tasks;
using CaldovaBakery.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CaldovaBakery.Controllers
{
    public class HomeController : Controller
    {
        private readonly BakeryContext database;
        public HomeController(BakeryContext database) => this.database = database;
        public async Task<IActionResult> Index() => View(await database.Products.AsNoTracking().OrderBy(product => product.ID).Take(3).ToListAsync());
        public IActionResult About() => View();
        public IActionResult Contact() => View();
        public IActionResult Store() => View();
        public IActionResult Error()
        {
            Response.StatusCode = 500;
            return View();
        }
    }
}