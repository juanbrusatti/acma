class ProjectsController < ApplicationController
  def index
    @projects = Project.all

    # Filtrar por búsqueda de nombre
    if params[:search].present?
      search_pattern = "%#{params[:search]}%"
      @projects = @projects.where("name LIKE ?", search_pattern)
    end

    # Filtrar por estado
    if params[:status].present? && params[:status] != "Todos"
      @projects = @projects.where(status: params[:status])
    end

    @projects = @projects.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
  end

  def new
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
    else
      @project = Project.new
    end
  end

  def create
    # Si el proyecto ya existe, actualizar con DVHs y glasscuttings (botón "Guardar como presupuesto")
    if params[:id].present?
      @project = Project.find(params[:id])
      if @project.update(project_params)
        redirect_to projects_path, notice: "Proyecto guardado como presupuesto exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    else
      # Crear nuevo proyecto básico (botón "Crear proyecto y continuar")
      @project = Project.new(project_basic_params)

      if @project.save
        # Redirigir a la misma vista pero con el proyecto creado
        redirect_to new_project_path(project_id: @project.id), notice: "Proyecto creado exitosamente. Ahora puedes agregar DVHs y vidrios."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def show
    @project = Project.find(params[:id])
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])

    # Log the parameters for debugging
    Rails.logger.info "Update params: #{params[:project]}"
    Rails.logger.info "Glasscuttings attributes: #{params[:project][:glasscuttings_attributes]}"
    Rails.logger.info "DVHs attributes: #{params[:project][:dvhs_attributes]}"

    if @project.update(project_params)
      Rails.logger.info "Project updated successfully"
      respond_to do |format|
        format.html { redirect_to projects_path, notice: "Proyecto actualizado exitosamente." }
        format.json {
          render json: {
            success: true,
            project: helpers.project_json_data(@project),
            status: @project.status
          }
        }
      end
    else
      Rails.logger.error "Project update failed: #{@project.errors.full_messages}"

      # Obtener mensajes de error traducidos
      error_messages = @project.errors.messages.map do |attribute, messages|
        # Si el mensaje ya está en español, usarlo tal cual, de lo contrario traducir el atributo
        if messages.first.is_a?(String) && messages.first.include?(' ')
          messages.first
        else
          attribute_name = @project.class.human_attribute_name(attribute)
          "#{attribute_name} #{messages.first}"
        end
      end

      respond_to do |format|
        format.html {
          redirect_to new_project_path(project_id: @project.id),
                      alert: error_messages.join(', ')
        }
        format.json {
          render json: { success: false, errors: error_messages },
                 status: :unprocessable_entity
        }
      end
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to projects_path, notice: "Proyecto eliminado exitosamente."
  end

  def pdf
    @project = Project.find(params[:id])
    respond_to do |format|
      format.pdf do
        response.headers['Content-Disposition'] = "attachment; filename=proyecto_#{@project.id}.pdf"
        render({ pdf: "proyecto_#{@project.id }_#{@project.name}", template: "projects/pdf" }.merge(helpers.pdf_main_options))
      end
      format.html { redirect_to project_path(@project) }
    end
  end

  def preview_pdf
    begin
      Rails.logger.info "=== Preview PDF - Usando precios del frontend ==="

      # Construir un objeto Project en memoria con los datos recibidos
      data = params.to_unsafe_h[:project] || {}
      Rails.logger.info "Datos recibidos: glasscuttings=#{data['glasscuttings_attributes']&.count || 0}, dvhs=#{data['dvhs_attributes']&.count || 0}"

      # Asegurar valores por defecto para campos obligatorios
      data['name'] ||= 'Proyecto Sin Nombre'
      data['description'] ||= ''
      data['phone'] ||= ''
      data['address'] ||= ''
      data['status'] ||= 'Pendiente'

      @project = Project.new(data)

      # NO recalcular precios - usar los enviados desde el frontend
      glasscuttings_total = 0.0
      dvhs_total = 0.0

      if @project.glasscuttings.present?
        @project.glasscuttings.each_with_index do |glass, index|
          # Usar el precio enviado desde el frontend, o 0 si no existe
          glass.price = glass.price.present? ? glass.price.to_f : 0.0
          glasscuttings_total += glass.price
          Rails.logger.info "Glasscutting #{index}: precio recibido #{glass.price}"
        end
      end

      if @project.dvhs.present?
        @project.dvhs.each_with_index do |dvh, index|
          # Usar el precio enviado desde el frontend, o 0 si no existe
          dvh.price = dvh.price.present? ? dvh.price.to_f : 0.0
          dvhs_total += dvh.price
          Rails.logger.info "DVH #{index}: precio recibido #{dvh.price}"
        end
      end

      # Calcular totales usando los precios enviados
      total = glasscuttings_total + dvhs_total
      iva = (total * 0.21).round(2)

      @project.define_singleton_method(:subtotal) { total }
      @project.define_singleton_method(:iva) { iva }
      @project.define_singleton_method(:total) { total + iva }

      Rails.logger.info "Totales: Glasscuttings=#{glasscuttings_total}, DVHs=#{dvhs_total}, Total=#{total}, IVA=#{iva}"

      respond_to do |format|
        format.pdf do
          response.headers['Content-Disposition'] = "attachment; filename=proyecto_preview.pdf"
          render({ pdf: "proyecto_preview", template: "projects/pdf" }.merge(helpers.pdf_preview_options))
        end
      end
    rescue => e
      Rails.logger.error "Error generando PDF preview: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      respond_to do |format|
        format.pdf { render plain: "Error generando PDF: #{e.message}", status: 500 }
        format.html { render plain: "Error generando PDF: #{e.message}", status: 500 }

      end
    end
  end

  # Optimize the project using the python microservice
  def optimize
    @project = Project.find(params[:id])
    require 'net/http'
    optimizer_url = ENV.fetch('OPTIMIZER_URL', 'http://optimizer:8000/optimize')
    uri = URI.parse(optimizer_url)

    pieces_to_cut, stock = create_microservice_params(stock_flag = params[:stock], scraps_flag = params[:scraps])

    call_microservice_optimizer(uri, pieces_to_cut, stock)
  end

  # View to confirm optimization results
  def confirm_optimization
    @project = Project.find(params[:id])
    # Pull optimization data from session
    @optimization_data = session[:optimization_data]

    if @optimization_data.nil?
      redirect_to project_path(@project), alert: "No hay datos de optimización disponibles."
    end
  end

  def accept_optimize
    @project = Project.find(params[:id])
    optimization_data = session[:optimization_data]

    if optimization_data.nil?
      redirect_to project_path(@project), alert: "No hay datos de optimización disponibles."
      return
    end

    new_scraps = optimization_data['new_scraps'] || []
    used_scraps = optimization_data['deleted_scraps'] || []
    used_stock = optimization_data['deleted_stock'] || []

    create_scraps(new_scraps) if new_scraps.any?
    delete_used_scraps(used_scraps) if used_scraps.any?
    delete_used_stock(used_stock) if used_stock.any?

    @project.update(date_of_optimization: Date.today)

    # Clean up session data
    session.delete(:optimization_data)
    session.delete(:zip_data)
    session.delete(:zip_filename)

    redirect_to project_path(@project), notice: "Optimización aceptada y stock actualizado!!"
  end

  # Cancel optimization process
  def cancel_optimize
    @project = Project.find(params[:id])
    # Clean up session data
    session.delete(:optimization_data)
    session.delete(:zip_data)
    session.delete(:zip_filename)
    redirect_to project_path(@project), notice: "Optimización cancelada."
  end

  # Download optimization ZIP file
  def download_optimization_zip
    @project = Project.find(params[:id])
    zip_data = session[:zip_data]
    zip_filename = session[:zip_filename] || "cutting_plan_visuals.zip"

    if zip_data
      send_data Base64.decode64(zip_data), filename: zip_filename, type: 'application/zip', disposition: 'attachment'
    else
      redirect_to project_path(@project), alert: "No hay archivo ZIP disponible."
    end
  end

  private

  def create_microservice_params(stock_flag = false, scraps_flag = false)
    pieces_to_cut = []
    glasscuttings = @project.glasscuttings
    dvhs = @project.dvhs

    # Convertir string params a boolean si es necesario
    stock_flag = stock_flag.to_s == 'true' || stock_flag == true
    scraps_flag = scraps_flag.to_s == 'true' || scraps_flag == true

    pieces_to_cut += glasscuttings.map do |cut|
      {
        id: cut.typology,
        width: cut.width,
        height: cut.height,
        quantity: 1,
        color: cut.color,
        glass_type: cut.glass_type,
        thickness: cut.thickness,
        type_opening: cut.type_opening
      }
    end

    pieces_to_cut += dvhs.flat_map do |dvh|
      [
        {
          id: dvh.typology,
          width: dvh.width,
          height: dvh.height,
          quantity: 1,
          # For DVHs, we send details of the first glasscutting
          color: dvh.glasscutting1_color,
          glass_type: dvh.glasscutting1_type,
          thickness: dvh.glasscutting1_thickness,
          type_opening: dvh.type_opening
        },
        {
          id: dvh.typology,
          width: dvh.width,
          height: dvh.height,
          quantity: 1,
          # For DVHs, we send details of the second glasscutting
          color: dvh.glasscutting2_color,
          glass_type: dvh.glasscutting2_type,
          thickness: dvh.glasscutting2_thickness,
          type_opening: dvh.type_opening
        }
      ]
    end

    pieces_to_cut = pieces_to_cut.as_json

    # Si ningún flag está activado, retornar sin stock
    if !stock_flag && !scraps_flag
      return pieces_to_cut, {}
    end

    stock = {}

    # Agregar glassplates si el flag está activado
    if stock_flag
      glassplates = Glassplate.all.map do |gp|
        gp.as_json.merge(
          color: gp.color,
          glass_type: gp.glass_type,
          thickness: gp.thickness
        )
      end
      stock[:glassplates] = glassplates
    end

    # Agregar scraps si el flag está activado
    if scraps_flag
      scraps = Scrap.all.map do |sc|
        sc.as_json.merge(
          color: sc.color,
          glass_type: sc.scrap_type,
          thickness: sc.thickness
        )
      end
      stock[:scraps] = scraps
    end

    return pieces_to_cut, stock
  end

  def call_microservice_optimizer(uri, pieces_to_cut, stock)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 180
    req = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' })   # Server expects JSON in body
    req.body = { pieces_to_cut: pieces_to_cut, stock: stock }.to_json # Send as pieces_to_cut and stock in body

    response = http.request(req)

    # Manage the response from the optimizer
    manage_response(response)

  end

  def manage_response(response)
    if response.code.to_i == 200
      content_type = response["content-type"] || response["Content-Type"]
      body = response.body

      # When the microservice returns (JSON + ZIP),
      # we save the JSON in @optimizer_summary and send the ZIP as a download.
      zip_bytes = nil
      zip_filename = "cutting_plan_visuals.zip"
      json_text = nil

      parsed_ok = false

      # Try with MIME parser from 'mail' gem (available in Rails)
      # Si esto no anda fijate de hacerlo manual matute.
      begin
        require 'mail'
        raw_mime = "Content-Type: #{content_type}\r\nMIME-Version: 1.0\r\n\r\n#{body}"
        mail = Mail.read_from_string(raw_mime)
        if mail&.multipart?
          json_part = mail.parts.find { |p| p.mime_type&.include?('application/json') }
          zip_part  = mail.parts.find { |p| p.mime_type&.include?('application/zip') }
          json_text = json_part&.decoded
          if zip_part
            zip_bytes = zip_part.body.decoded
            zip_filename = zip_part.filename.presence || zip_filename
          end
          parsed_ok = true
        end
      rescue LoadError, StandardError => e
        Rails.logger.warn "Fallo parseo MIME con 'mail': #{e.class} #{e.message}."
      end

      # Persistir JSON en variable de instancia para uso posterior
      begin
        @optimizer_summary = json_text.present? ? JSON.parse(json_text) : nil
      rescue JSON::ParserError => e
        Rails.logger.warn "No se pudo parsear JSON de resumen: #{e.message}"
        @optimizer_summary = json_text # guardar texto crudo como último recurso
      end

      # Guardar los datos de optimización en la sesión
      session[:optimization_data] = @optimizer_summary
      session[:zip_data] = Base64.encode64(zip_bytes) if zip_bytes
      session[:zip_filename] = zip_filename

      # Redirigir a la vista de confirmación
      redirect_to confirm_optimization_project_path(@project)

    else
      Rails.logger.error "Optimizer failed: #{response.code} #{response.body[0..200]}"
      redirect_to project_path(@project), alert: "Error al ejecutar optimizador (#{response.code})"
    end
  rescue => e
    Rails.logger.error "Optimizer request error: #{e.message}"
    redirect_to project_path(@project), alert: "Error conectando al servicio de optimización"
  end

  # Private methods for scraps creation post optimization
  def create_scraps(new_scraps_data)
    for scrap_data in new_scraps_data
      Scrap.create!(
        width: scrap_data['width'],
        height: scrap_data['height'],
        thickness: scrap_data['thickness'],
        scrap_type: scrap_data['glass_type'],
        color: scrap_data['color'],
        input_work: @project.name
      )
    end
  end

  def delete_used_scraps(used_scraps_data)
    for scrap_data in used_scraps_data
      scrap = Scrap.find_by(scrap_data["id"])
      scrap.destroy if scrap
    end
  end

  def delete_used_stock(used_stock_data)
    for stock_data in used_stock_data
      glassplate = Glassplate.find_by(stock_data["id"])
      glassplate.destroy if glassplate
    end
  end

  def project_basic_params
    params.require(:project).permit(:name, :phone, :address, :delivery_date, :description, :status)
  end

  def project_params
    # First get the basic parameters
    permitted = params.require(:project).permit(
      :name,
      :phone,
      :address,
      :delivery_date,
      :description,
      :status,
      :price,
      :price_without_iva,
      glasscuttings_attributes: [ :id, :glass_type, :thickness, :height, :width, :color, :typology, :type_opening, :price ],
      dvhs_attributes: [
        :id,
        :innertube,
        :typology,
        :height,
        :width,
        :type_opening,
        :glasscutting1_type,
        :glasscutting1_thickness,
        :glasscutting1_color,
        :glasscutting2_type,
        :glasscutting2_thickness,
        :glasscutting2_color,
        :price
      ]
    )

    # Handle glasscuttings_attributes manually
    if params[:project][:glasscuttings_attributes].present?
      glasscuttings_attrs = {}
      params[:project][:glasscuttings_attributes].each do |key, value|
        glasscuttings_attrs[key] = value.permit(
          :id, :_destroy, :glass_type, :thickness, :height, :width,
          :color, :typology, :price, :type_opening
        ) if value.is_a?(ActionController::Parameters)
      end
      permitted[:glasscuttings_attributes] = glasscuttings_attrs
    end

    # Handle dvhs_attributes manually
    if params[:project][:dvhs_attributes].present?
      dvhs_attrs = {}
      params[:project][:dvhs_attributes].each do |key, value|
        dvhs_attrs[key] = value.permit(
          :id, :_destroy, :innertube, :typology, :height, :width, :type_opening,
          :glasscutting1_type, :glasscutting1_thickness, :glasscutting1_color,
          :glasscutting2_type, :glasscutting2_thickness, :glasscutting2_color, :price
        ) if value.is_a?(ActionController::Parameters)
      end
      permitted[:dvhs_attributes] = dvhs_attrs
    end

    permitted
  end
end
