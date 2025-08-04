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
end
