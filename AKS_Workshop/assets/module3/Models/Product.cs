using System.ComponentModel.DataAnnotations;

namespace CaldovaBakery.Models
{
    public class Product
    {
        public int ID { get; set; }

        [Required, StringLength(100)]
        public string Name { get; set; }

        [Range(typeof(decimal), "0.01", "9999.99")]
        public decimal Price { get; set; }

        [Required, StringLength(500)]
        [RegularExpression(@"^(/images/[a-zA-Z0-9._-]+|https://[^\s]+)$", ErrorMessage = "Use a local /images/ path or an HTTPS image URL.")]
        public string Image { get; set; }

        [Required, StringLength(2000)]
        public string Description { get; set; }

        [Required, StringLength(50)]
        public string Category { get; set; } = "Pastries";
    }
}