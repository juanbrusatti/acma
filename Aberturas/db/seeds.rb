# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
<<<<<<< HEAD

# Crear proyectos de ejemplo
projects_data = [
  {
    name: "Instalación de Aberturas - Casa López",
    description: "Instalación completa de ventanas y puertas en residencia familiar",
    status: "En Proceso",
    delivery_date: Date.current + 15.days
  },
  {
    name: "Renovación Comercial - Local Centro",
    description: "Reemplazo de aberturas en local comercial del centro",
    status: "Terminado",
    delivery_date: Date.current - 5.days
  },
  {
    name: "Proyecto Residencial - Edificio Norte",
    description: "Instalación de aberturas en edificio de 12 departamentos",
    status: "Pendiente",
    delivery_date: Date.current + 30.days
  },
  {
    name: "Oficinas Corporativas - Torre Sur",
    description: "Aberturas para oficinas corporativas en torre de 20 pisos",
    status: "En Proceso",
    delivery_date: Date.current + 10.days
  },
  {
    name: "Casa de Campo - Estancia Los Pinos",
    description: "Aberturas especiales para casa de campo con vista al lago",
    status: "Terminado",
    delivery_date: Date.current - 10.days
  }
]

projects_data.each do |project_data|
  Project.find_or_create_by!(name: project_data[:name]) do |project|
    project.description = project_data[:description]
    project.status = project_data[:status]
    project.delivery_date = project_data[:delivery_date]
  end
end

puts "✅ Proyectos de ejemplo creados exitosamente!"
=======
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
  glass_type: "Incoloro",
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
  glass_type: "Laminado 3+3",
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
  glass_type: "DVH 4/9/4",
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
  glass_type: "Espejo",
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

# Example scraps
Glassplate.create!(
  glass_type: "Incoloro",
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
  glass_type: "Laminado 3+3",
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
  glass_type: "Espejo",
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
  glass_type: "Templado",
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
  glass_type: "Doble",
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
>>>>>>> main
