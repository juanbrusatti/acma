require "ostruct"

class StaticPagesController < ApplicationController
  def home
    load_dashboard_data
  end

  private

  def load_dashboard_data
    @stock_data = load_stock_data
    @projects_data = load_projects_data
    @recent_projects = load_recent_projects
  end

  def load_stock_data
    {
      total_sheets: 1250,
      available_scraps: 320
    }
  end

  def load_projects_data
    {
      active_projects: 12,
      completed_this_month: 3
    }
  end

  def load_recent_projects
    [
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
