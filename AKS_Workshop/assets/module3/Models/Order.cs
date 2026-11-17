using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;

namespace CaldovaBakery.Models
{
    public class Order
    {
        public int ID { get; set; }
        public DateTime CreatedUtc { get; set; } = DateTime.UtcNow;
        [Required, StringLength(100)]
        public string CustomerName { get; set; }
        [Required, EmailAddress, StringLength(200)]
        public string Email { get; set; }
        [StringLength(500)]
        public string Notes { get; set; }
        public List<OrderItem> Items { get; set; } = new List<OrderItem>();
    }

    public class OrderItem
    {
        public int ID { get; set; }
        public int OrderID { get; set; }
        [Required, StringLength(100)]
        public string ProductName { get; set; }
        public decimal UnitPrice { get; set; }
        public int Quantity { get; set; }
    }

    public class CartItem
    {
        public int ProductID { get; set; }
        public int Quantity { get; set; }
    }

    public class CartLine
    {
        public Product Product { get; set; }
        public int Quantity { get; set; }
        public decimal Total => Product.Price * Quantity;
    }

    public class CartViewModel
    {
        public List<CartLine> Lines { get; set; } = new List<CartLine>();
        public decimal Total => Lines.Sum(line => line.Total);
        public int Count => Lines.Sum(line => line.Quantity);
    }

    public class CheckoutViewModel
    {
        [Required, StringLength(100), Display(Name = "Your name")]
        public string CustomerName { get; set; }
        [Required, EmailAddress, StringLength(200)]
        public string Email { get; set; }
        [StringLength(500), Display(Name = "Pickup notes")]
        public string Notes { get; set; }
        public CartViewModel Cart { get; set; } = new CartViewModel();
    }

    public class CatalogViewModel
    {
        public List<Product> Products { get; set; } = new List<Product>();
        public List<string> Categories { get; set; } = new List<string>();
        public string Search { get; set; }
        public string Category { get; set; }
    }
}