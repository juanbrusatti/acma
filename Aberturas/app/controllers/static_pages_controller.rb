require "ostruct"

class StaticPagesController < ApplicationController
  def home
    @stock_planchas = 1250
    @sobrantes_disponibles = 320
    @proyectos_en_curso = 12
    @proyectos_finalizados_mes = 3

    # Placeholder for recent projects data
    # In a real application, you would fetch these from your database
    @recent_projects = [
      OpenStruct.new(
        client_name: "Constructora del Sol",
        description: "Edificio \"Amanecer\"",
        status: "En Proceso",
        delivery_date: Date.parse("2025-07-15")
      ),
      OpenStruct.new(
        client_name: "Familia Pérez",
        description: "Cerramiento de balcón",
        status: "Terminado",
        delivery_date: Date.parse("2025-06-28")
      ),
      OpenStruct.new(
        client_name: "Oficinas Central",
        description: "Divisiones internas",
        status: "En Proceso",
        delivery_date: Date.parse("2025-07-05")
      )
    ]
  end
end
