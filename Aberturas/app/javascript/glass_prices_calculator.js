// Handles real-time calculation of selling prices based on buying price and percentage markup
document.addEventListener("DOMContentLoaded", function() {
  
  // Sets up price calculation for all glass price forms in the page
  function setupPriceCalculation() {
    // Find all forms that edit glass prices (identified by turbo-frame attribute)
    const forms = document.querySelectorAll('form[data-turbo-frame^="glass_price_"]');
    
    forms.forEach(form => {
      // Get references to the three main input fields in each form
      const buyingPriceField = form.querySelector('input[name="glass_price[buying_price]"]');
      const percentageField = form.querySelector('input[name="glass_price[percentage]"]');
      const sellingPriceField = form.querySelector('input[name="glass_price[selling_price]"]');
      
      // Only proceed if all required fields are present
      if (buyingPriceField && percentageField && sellingPriceField) {
        
        // Function to calculate and update the selling price
        function calculateSellingPrice() {
          // Parse input values, defaulting to 0 if invalid
          const buyingPrice = parseFloat(buyingPriceField.value) || 0;
          const percentage = parseFloat(percentageField.value) || 0;
          
          // Calculate selling price only if we have valid inputs
          if (buyingPrice > 0 && percentage >= 0) {
            // Formula: selling_price = buying_price * (1 + percentage/100)
            const sellingPrice = buyingPrice * (1 + percentage / 100);
            sellingPriceField.value = sellingPrice.toFixed(2);
          } else {
            // Clear the field if inputs are invalid
            sellingPriceField.value = '';
          }
        }
        
        // Attach event listeners to trigger calculation on input changes
        buyingPriceField.addEventListener('input', calculateSellingPrice);
        percentageField.addEventListener('input', calculateSellingPrice);
        
        // Calculate immediately if there are already values present
        calculateSellingPrice();
      }
    });
  }
  
  // Execute when the page initially loads
  setupPriceCalculation();
  
  // Re-execute when Turbo updates content dynamically (for inline editing)
  document.addEventListener("turbo:frame-load", setupPriceCalculation);
});
