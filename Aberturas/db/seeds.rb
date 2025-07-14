# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

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
