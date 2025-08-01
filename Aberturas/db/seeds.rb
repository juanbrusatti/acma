# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Crear proyectos de ejemplo
projects_data = [
  {
    name: "Instalación de Aberturas - Casa López",
    description: "Instalación completa de ventanas y puertas en residencia familiar",
    status: "En Proceso",
    delivery_date: Date.current + 15.days,
    phone: "011-4555-1234",
    address: "Av. Corrientes 1234, Buenos Aires"
  },
  {
    name: "Renovación Comercial - Local Centro",
    description: "Reemplazo de aberturas en local comercial del centro",
    status: "Terminado",
    delivery_date: Date.current - 5.days,
    phone: "011-4555-5678",
    address: "Florida 567, Capital Federal"
  },
  {
    name: "Proyecto Residencial - Edificio Norte",
    description: "Instalación de aberturas en edificio de 12 departamentos",
    status: "Pendiente",
    delivery_date: Date.current + 30.days,
    phone: "011-4555-9012",
    address: "Av. Santa Fe 2890, Buenos Aires"
  },
  {
    name: "Oficinas Corporativas - Torre Sur",
    description: "Aberturas para oficinas corporativas en torre de 20 pisos",
    status: "En Proceso",
    delivery_date: Date.current + 10.days,
    phone: "011-4555-3456",
    address: "Puerto Madero 123, Buenos Aires"
  },
  {
    name: "Casa de Campo - Estancia Los Pinos",
    description: "Aberturas especiales para casa de campo con vista al lago",
    status: "Terminado",
    delivery_date: Date.current - 10.days,
    phone: "011-4555-7890",
    address: "Ruta 8 Km 45, Pilar"
  }
]

projects_data.each do |project_data|
  Project.find_or_create_by!(name: project_data[:name]) do |project|
    project.description = project_data[:description]
    project.status = project_data[:status]
    project.delivery_date = project_data[:delivery_date]
    project.phone = project_data[:phone]
    project.address = project_data[:address]
  end
end

puts "✅ Proyectos de ejemplo creados exitosamente!"

# Create some fake data
puts "Creando datos de ejemplo para glassplates..."

# Example complete sheets
Glassplate.create!(
  glass_type: "FLO", # Changed from "Float" to "FLO"
  thickness: "5mm",
  color: "INC", # Changed from "Incoloro" to "INC"
  width: 2500,
  height: 3600,
  standard_measures: "2500x3600",
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false,
  work: nil,
  origin: "Proveedor A"
)

Glassplate.create!(
  glass_type: "LAM", # Changed from "Laminado" to "LAM"
  thickness: "3+3",
  color: "INC", # Changed from "Incoloro" to "INC"
  width: 2500,
  height: 3600,
  standard_measures: "2500x3600",
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false,
  work: nil,
  origin: "Proveedor B"
)

Glassplate.create!(
  glass_type: "COL", # Changed from "Cool Lite" to "COL"
  thickness: "5mm",
  color: "GRS", # Changed from "Gris" to "GRS"
  width: 2500,
  height: 3600,
  standard_measures: "2500x3600",
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false,
  work: nil,
  origin: "Proveedor A"
)

Glassplate.create!(
  glass_type: "FLO", # Changed from "Float" to "FLO"
  thickness: "4+4",
  color: "BRC", # Changed from "Bronce" to "BRC"
  width: 2440,
  height: 3660,
  standard_measures: "2440x3660",
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false,
  work: nil,
  origin: "Proveedor C"
)

# Example scraps
Glassplate.create!(
  glass_type: "FLO", # Changed from "Float" to "FLO"
  thickness: "5mm",
  color: "INC", # Changed from "Incoloro" to "INC"
  width: 800,
  height: 1200,
  standard_measures: "800x1200",
  location: "Estante A3",
  status: "disponible",
  is_scrap: true,
  work: "Ventana Oficina",
  origin: "Recorte interno"
)

Glassplate.create!(
  glass_type: "LAM", # Changed from "Laminado" to "LAM"
  thickness: "3+3",
  color: "STG", # Changed from "Esmerilado" to "STG" (satinado gris as closest match)
  width: 500,
  height: 950,
  standard_measures: "500x950",
  location: "Estante B1",
  status: "disponible",
  is_scrap: true,
  work: "Puerta Principal",
  origin: "Recorte interno"
)

Glassplate.create!(
  glass_type: "FLO", # Changed from "Float" to "FLO"
  thickness: "4+4",
  color: "GRS", # Changed from "Gris" to "GRS"
  width: 1500,
  height: 400,
  standard_measures: "1500x400",
  location: "Estante A1",
  status: "disponible",
  is_scrap: true,
  work: "Baño Principal",
  origin: "Recorte interno"
)

Glassplate.create!(
  glass_type: "COL", # Changed from "Cool Lite" to "COL"
  thickness: "5+5",
  color: "BRC", # Changed from "Bronce" to "BRC"
  width: 1200,
  height: 800,
  standard_measures: "1200x800",
  location: "Estante C2",
  status: "disponible",
  is_scrap: true,
  work: "Divisor Cocina",
  origin: "Recorte interno"
)

Glassplate.create!(
  glass_type: "LAM", # Changed from "Laminado" to "LAM"
  thickness: "4+4",
  color: "GRS", # Changed from "Gris" to "GRS"
  width: 900,
  height: 600,
  standard_measures: "900x600",
  location: "Estante D1",
  status: "reservado",
  is_scrap: true,
  work: "Ventana Pequeña",
  origin: "Recorte interno"
)

puts "Datos de ejemplo creados exitosamente!"

# Crear precios de ejemplo para todas las combinaciones posibles de GlassPrice
puts "Creando precios de ejemplo para todas las combinaciones de vidrios..."

# Precios de ejemplo basados en valores reales del mercado
sample_prices = {
  # LAM (Laminado) - precios por m²
  { glass_type: "LAM", thickness: "3+3", color: "INC" } => 32776.47,
  { glass_type: "LAM", thickness: "3+3", color: "BLS" } => 60613.11, # Changed from "ESM" to "BLS"
  { glass_type: "LAM", thickness: "4+4", color: "INC" } => 40938.20,
  { glass_type: "LAM", thickness: "5+5", color: "INC" } => 49212.72,

  # FLO (Float) - precios por m²
  { glass_type: "FLO", thickness: "5mm", color: "INC" } => 13379.15,
  { glass_type: "FLO", thickness: "5mm", color: "GRS" } => 20088.71, # Changed from "GRS/BCE" to "GRS"
  { glass_type: "FLO", thickness: "5mm", color: "BRC" } => 20088.71, # Added BRC with the same price

  # COL (Cool Lite) - precios por m²
  { glass_type: "COL", thickness: "4+4", color: "STB" } => 94080.59, # Changed from "-" to "STB"
  { glass_type: "COL", thickness: "4+4", color: "STG" } => 94080.59, # Added STG variant
  { glass_type: "COL", thickness: "4+4", color: "NTR" } => 94080.59  # Added NTR variant
}

# Create all glassprice registers
sample_prices.each do |combination, price_m2|
  glass_price = GlassPrice.find_or_initialize_by(combination)
  # Using buying_price and percentage to calculate selling_price based on the GlassPrice model
  glass_price.buying_price = price_m2
  glass_price.percentage = 20 # Setting a 20% markup

  if glass_price.save
    puts "✅ Precio creado: #{combination[:glass_type]} #{combination[:thickness]} #{combination[:color]} - $#{price_m2}/m²"
  else
    puts "❌ Error creando precio para: #{combination[:glass_type]} #{combination[:thickness]} #{combination[:color]}"
    puts "   Errores: #{glass_price.errors.full_messages.join(', ')}"
  end
end

puts "✅ Precios de ejemplo para todas las combinaciones creados exitosamente!"

# Create supply prices using the BASICS constant from the Supply model
puts "Creando precios de ejemplo para insumos..."

Supply::BASICS.each_with_index do |name, index|
  price = 1000 * (index + 1) # 1000, 2000, 3000

  supply = Supply.find_or_initialize_by(name: name)
  supply.price = price.to_f.round(2)

  if supply.save
    puts "✅ Precio creado: #{name} - $#{price}"
  else
    puts "❌ Error creando precio para: #{name}"
    puts "   Errores: #{supply.errors.full_messages.join(', ')}"
  end
end

puts "✅ Precios de insumos creados exitosamente!"
