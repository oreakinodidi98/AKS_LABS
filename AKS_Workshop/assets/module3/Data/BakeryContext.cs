using CaldovaBakery.Models;
using Microsoft.EntityFrameworkCore;

namespace CaldovaBakery.Data
{
    public class BakeryContext : DbContext
    {
        public BakeryContext(DbContextOptions<BakeryContext> options) : base(options) { }

        public DbSet<Product> Products { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            if (Database.IsSqlServer())
            {
                builder.Entity<Product>().Property(product => product.Price).HasColumnType("decimal(10,2)");
                builder.Entity<OrderItem>().Property(item => item.UnitPrice).HasColumnType("decimal(10,2)");
            }
            builder.Entity<Order>().HasMany(order => order.Items).WithOne().HasForeignKey(item => item.OrderID);
        }
    }
}