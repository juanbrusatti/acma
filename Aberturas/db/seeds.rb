# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Crear datos de ejemplo para glassplates
puts "Creando datos de ejemplo para glassplates..."

# Planchas completas
Glassplate.create!(
  type: "Incoloro",
  thickness: "4mm",
  color: "transparente",
  width: 2500,
  height: 3600,
  standard_measures: "2500x3600",
  quantity: 15,
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false
)

Glassplate.create!(
  type: "Laminado 3+3",
  thickness: "6mm",
  color: "transparente",
  width: 2500,
  height: 3600,
  standard_measures: "2500x3600",
  quantity: 8,
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false
)

Glassplate.create!(
  type: "DVH 4/9/4",
  thickness: "17mm",
  color: "transparente",
  width: 2500,
  height: 3600,
  standard_measures: "2500x3600",
  quantity: 12,
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false
)

Glassplate.create!(
  type: "Espejo",
  thickness: "3mm",
  color: "plata",
  width: 2440,
  height: 3660,
  standard_measures: "2440x3660",
  quantity: 20,
  location: "Estante Principal",
  status: "disponible",
  is_scrap: false
)

# Sobrantes/Recortes
Glassplate.create!(
  type: "Incoloro",
  thickness: "4mm",
  color: "transparente",
  width: 800,
  height: 1200,
  standard_measures: "800x1200",
  quantity: 1,
  location: "Estante A3",
  status: "disponible",
  is_scrap: true
)

Glassplate.create!(
  type: "Laminado 3+3",
  thickness: "6mm",
  color: "transparente",
  width: 500,
  height: 950,
  standard_measures: "500x950",
  quantity: 1,
  location: "Estante B1",
  status: "disponible",
  is_scrap: true
)

Glassplate.create!(
  type: "Espejo",
  thickness: "3mm",
  color: "plata",
  width: 1500,
  height: 400,
  standard_measures: "1500x400",
  quantity: 1,
  location: "Estante A1",
  status: "reservado",
  is_scrap: true
)

Glassplate.create!(
  type: "Templado",
  thickness: "8mm",
  color: "gris",
  width: 1200,
  height: 800,
  standard_measures: "1200x800",
  quantity: 1,
  location: "Estante C2",
  status: "disponible",
  is_scrap: true
)

Glassplate.create!(
  type: "Doble",
  thickness: "12mm",
  color: "azul",
  width: 900,
  height: 600,
  standard_measures: "900x600",
  quantity: 1,
  location: "Estante D1",
  status: "disponible",
  is_scrap: true
)

puts "Datos de ejemplo creados exitosamente!"
