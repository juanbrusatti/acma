# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create some fake data
puts "Creando datos de ejemplo para glassplates..."

# Example complete sheets
Glassplate.create!(
  glass_type: "Float",
  thickness: "5mm",
  color: "Incoloro",
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
  glass_type: "Laminado",
  thickness: "3+3",
  color: "Incoloro",
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
  glass_type: "Cool Lite",
  thickness: "5mm",
  color: "Gris",
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
  glass_type: "Float",
  thickness: "4+4",
  color: "Bronce",
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
  glass_type: "Float",
  thickness: "5mm",
  color: "Incoloro",
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
  glass_type: "Laminado",
  thickness: "3+3",
  color: "Esmerilado",
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
  glass_type: "Float",
  thickness: "4+4",
  color: "Gris",
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
  glass_type: "Cool Lite",
  thickness: "5+5",
  color: "Bronce",
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
  glass_type: "Laminado",
  thickness: "4+4",
  color: "Gris",
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
