require "ostruct"

class StaticPagesController < ApplicationController
  def home
    load_dashboard_data
  end

  private

  def load_dashboard_data
    @stock_data = load_stock_data
    @projects_data = load_projects_data
    @recent_projects = Project.all.order(created_at: :desc).limit(3).map do |project|
      project
    end
  end

  def load_stock_data
    {
      glassplates: {
        total: Glassplate.count.to_i
      },
      scraps: {
        total: Scrap.count.to_i
      }
    }
  end

  def load_projects_data
    {
      active_projects: Project.where(status: 'En Proceso').count,
      completed_this_month: Project.where(status: 'Terminado', updated_at: Time.current.beginning_of_month..Time.current.end_of_month).count
    }
  end
end
