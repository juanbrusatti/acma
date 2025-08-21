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
      respond_to do |format|
        format.html { 
          # Redirect back to edit form with errors
          redirect_to new_project_path(project_id: @project.id), alert: "Error al actualizar: #{@project.errors.full_messages.join(', ')}"
        }
        format.json {
          render json: { success: false, errors: @project.errors.full_messages }, status: :unprocessable_entity
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

  private

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
      :price_without_iva
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