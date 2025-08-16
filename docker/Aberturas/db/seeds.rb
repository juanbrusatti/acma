puts "Creando datos de ejemplo para scraps..."

Scrap.create!(
  ref_number: "S001",
  scrap_type: "LAM",
  thickness: "3+3",
  color: "INC",
  width: 1200,
  height: 800,
  output_work: "Obra 1",
  status: "Disponible"
)

Scrap.create!(
  ref_number: "S002",
  scrap_type: "FLO",
  thickness: "5mm",
  color: "GRS",
  width: 900,
  height: 600,
  output_work: "Obra 2",
  status: "Reservado"
)

Scrap.create!(
  ref_number: "S003",
  scrap_type: "COL",
  thickness: "4+4",
  color: "STB",
  width: 700,
  height: 500,
  output_work: "Obra 3",
  status: "Disponible"
)

puts "✅ Retazos de ejemplo creados exitosamente!"
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
  quantity: 10,
)

Glassplate.create!(
  glass_type: "LAM", # Changed from "Laminado" to "LAM"
  thickness: "3+3",
  color: "INC", # Changed from "Incoloro" to "INC"
  width: 2500,
  height: 3600,
  quantity: 5,
)

Glassplate.create!(
  glass_type: "COL", # Changed from "Cool Lite" to "COL"
  thickness: "4+4",
  color: "NTR", # Changed from "Gris" to "GRS"
  width: 2500,
  height: 3600,
  quantity: 8,
)

Glassplate.create!(
  glass_type: "LAM", # Changed from "Float" to "FLO"
  thickness: "4+4",
  color: "INC", # Changed from "Bronce" to "BRC"
  width: 2440,
  height: 3660,
  quantity: 5,
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

# Set MEP rate first for peso price calculation
AppConfig.set_mep_rate(1200.0) # Using 1200 as example MEP rate

Supply::BASICS.each_with_index do |name, index|
  price_usd = (5.0 + index * 2).round(2) # 5.00, 7.00, 9.00, 11.00, 13.00 USD

  supply = Supply.find_or_initialize_by(name: name)
  supply.price_usd = price_usd

  if supply.save
    puts "✅ Precio creado: #{name} - US$#{price_usd} (AR$#{supply.price_peso})"
  else
    puts "❌ Error creando precio para: #{name}"
    puts "   Errores: #{supply.errors.full_messages.join(', ')}"
  end
end

puts "✅ Precios de insumos creados exitosamente!"
