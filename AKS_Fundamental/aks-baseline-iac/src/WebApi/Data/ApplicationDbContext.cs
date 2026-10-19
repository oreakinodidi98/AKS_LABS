using Microsoft.EntityFrameworkCore;

namespace WebApi.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Product> Products { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        modelBuilder.Entity<Product>().HasData(
            new Product { Id = 1, Name = "Sample Product 1", Price = 29.99m },
            new Product { Id = 2, Name = "Sample Product 2", Price = 49.99m },
            new Product { Id = 3, Name = "Sample Product 3", Price = 99.99m }
        );
    }
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
}
