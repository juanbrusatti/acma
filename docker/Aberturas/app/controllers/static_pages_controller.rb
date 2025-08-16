require "ostruct"

# === STATIC PAGES CONTROLLER ===
class StaticPagesController < ApplicationController
  def home
    load_dashboard_data
  end

  private

  # === DASHBOARD DATA LOADING ===
  def load_dashboard_data
    @stock_data = load_stock_data
    @projects_data = load_projects_data
    @recent_projects = Project.order(created_at: :desc).limit(3)
  end

  # === STOCK DATA LOADING ===
  def load_stock_data
    {
      total_sheets: Glassplate.complete_sheets.count,
      available_scraps: Glassplate.scraps.count,
    }
  end

  # === PROJECTS DATA LOADING ===
  def load_projects_data
    {
      active_projects: Project.where(status: 'En Proceso').count,
      completed_this_month: Project.where(status: 'Terminado', updated_at: Time.current.beginning_of_month..Time.current.end_of_month).count
    }
  end
end
