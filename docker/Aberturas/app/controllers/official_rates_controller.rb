class OfficialRatesController < ApplicationController
  before_action :set_official_rate, only: [:show]

  def index
    # Paginación simple sin will_paginate por ahora
    page = params[:page].to_i
    page = 1 if page < 1
    per_page = 20
    offset = (page - 1) * per_page

    @official_rates = OfficialRateHistory.recent.limit(per_page).offset(offset)
    @total_count = OfficialRateHistory.count
    @current_page = page
    @total_pages = (@total_count.to_f / per_page).ceil

    @latest_rate = OfficialRateHistory.latest_rate
    @yesterday_rate = OfficialRateHistory.yesterday_rate
    @today_rate = OfficialRateHistory.today_rate
    @system_active = AppConfig.official_rate_system_active?

    # Estadísticas del último mes
    @month_stats = OfficialRateHistory.statistics_for_period(
      1.month.ago.to_date,
      Date.current
    )
  end

  def show
    @change_direction = @official_rate.change_direction
    @is_significant = @official_rate.significant_change?
  end

  def update_manual
    begin
      # Ejecutar el job de actualización manualmente
      UpdateOfficialRateJob.perform_now('manual')

      respond_to do |format|
            # HTML y JSON: establecen flash; en Turbo usamos solo redirect sin duplicar flash.
        format.html { redirect_to glass_prices_path, notice: "Cotización oficial actualizada manualmente." }
        format.json { render json: { success: true, message: "Cotización oficial actualizada manualmente." } }
        format.turbo_stream { redirect_to glass_prices_path, status: :see_other, notice: "Cotización oficial actualizada manualmente." }
      end
    rescue => e
      Rails.logger.error "Error en actualización manual: #{e.message}"

      respond_to do |format|
        format.html { redirect_to glass_prices_path, alert: "Error al actualizar la cotización: #{e.message}" }
        format.json { render json: { success: false, message: "Error al actualizar la cotización: #{e.message}" } }
        format.turbo_stream { redirect_to glass_prices_path, status: :see_other, alert: "Error al actualizar la cotización: #{e.message}" }
      end
    end
  end

  def api_status
    @api_status = OfficialRateApiService.api_status_info
    @availability = OfficialRateApiService.check_api_availability
  end

  private

  def set_official_rate
    @official_rate = OfficialRateHistory.find(params[:id])
  end
end
