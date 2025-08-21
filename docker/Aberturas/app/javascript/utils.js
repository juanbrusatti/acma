export function getSwalConfig() {
    return {
        toast: true,
        position: 'top-end',
        icon: 'warning',
        showConfirmButton: false,
        timer: 4000,
        timerProgressBar: true
    }
}

// Price utilities shared across modules
// Looks up price per m2 for a given glass configuration from window.GLASS_PRICES
export function getGlassPriceM2(type, thickness, color) {
  if (!window.GLASS_PRICES) return 0;
  const found = window.GLASS_PRICES.find(p =>
    p.glass_type === type && p.thickness === thickness && p.color === color
  );
  return found ? found.selling_price : 0;
}

// Calculate total innertube price including 4 fixed angles, using global price tables
export function calculateInnertubeTotal(innertubeSize, perimeterM) {
  const pricePerMeter = window.INNERTUBE_PRICES ? (window.INNERTUBE_PRICES[innertubeSize] || 0) : 0;
  const linearCost = perimeterM * pricePerMeter;
  const anglePrice = window.SUPPLY_PRICES ? (window.SUPPLY_PRICES['Angulos'] || 0) : 0;
  const anglesCost = anglePrice * 4;
  return linearCost + anglesCost;
}

// Calculates total DVH price (two panes + innertube with angles)
export function getDvhTotalGlassPrice(height, width, glass1, glass2, innertubeSize) {
  const area = (height * width) / 1000000; // m2
  const perimeter = 2 * ((height / 1000) + (width / 1000)); // m

  const price1 = getGlassPriceM2(glass1.type, glass1.thickness, glass1.color);
  const price2 = getGlassPriceM2(glass2.type, glass2.thickness, glass2.color);

  const glassPrice = area * (price1 + price2);
  const innertubePrice = calculateInnertubeTotal(innertubeSize, perimeter);

  return glassPrice + innertubePrice;
}

// Validation helpers
// fields: array of { key, label }
export function requireFields(values, fields) {
  if (!values || !fields) return null;
  return fields.find(f => !values[f.key] || String(values[f.key]).trim() === '');
}

// Returns null if ok, otherwise an error message string
export function validateQuantity(q, min = 1, max = 100) {
  const n = parseInt(q, 10);
  if (isNaN(n) || n < min || n > max) {
    return `La cantidad debe estar entre ${min} y ${max}`;
  }
  return null;
}
