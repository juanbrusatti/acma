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
      @project = Project.includes(:glasscuttings, :dvhs).find(params[:project_id])
    else
      @project = Project.new
    end
  end

  def create
    if params[:project_id].present? || params[:id].present?
      # Si estamos actualizando un proyecto existente
      update
    else
      # Crear nuevo proyecto
      @project = Project.new(project_basic_params)

      if @project.save
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
    @project = Project.find(params[:id] || params[:project_id])
    
    # Debug: Mostrar los parámetros recibidos
    Rails.logger.info "=== Parámetros recibidos en update ==="
    Rails.logger.info "project_params: #{project_params.inspect}"
    Rails.logger.info "project_basic_params: #{project_basic_params.inspect}"
    
    # Actualizar los parámetros del proyecto, incluyendo vidrios y DVHs
    if @project.update(project_params.merge(project_basic_params))
      # Debug: Mostrar el estado después de la actualización
      Rails.logger.info "=== Proyecto actualizado exitosamente ==="
      Rails.logger.info "Glasscuttings: #{@project.glasscuttings.count}"
      
      respond_to do |format|
        format.html { 
          redirect_to projects_path, 
          notice: "Proyecto actualizado exitosamente." 
        }
        format.json {
          render json: {
            success: true,
            project: helpers.project_json_data(@project),
            status: @project.status,
            notice: 'Los cambios se guardaron correctamente.'
          }
        }
      end
    else
      respond_to do |format|
        format.html { 
          if @project.persisted?
            render :new, status: :unprocessable_entity 
          else
            render :edit, status: :unprocessable_entity
          end
        }
        format.json {
          render json: { 
            success: false, 
            errors: @project.errors.full_messages 
          }, status: :unprocessable_entity
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
    params.require(:project).permit(:name, :phone, :address, :delivery_date, :description, :status, :price, :price_without_iva)
  end

  def project_params
    # Debug: Mostrar los parámetros recibidos
    Rails.logger.info "=== Parámetros recibidos en project_params ==="
    Rails.logger.info "Parámetros crudos: #{params[:project].inspect}"
    
    # Definir los parámetros permitidos
    permitted_params = params.require(:project).permit(
      :name,
      :phone,
      :address,
      :delivery_date,
      :description,
      :status,
      :price,
      :price_without_iva,
      glasscuttings_attributes: [
        :id,
        :glass_type,
        :thickness,
        :height,
        :width,
        :color,
        :typology,
        :price,
        :_destroy
      ],
      dvhs_attributes: [
        :id,
        :innertube,
        :typology,
        :height,
        :width,
        :glasscutting1_type,
        :glasscutting1_thickness,
        :glasscutting1_color,
        :glasscutting2_type,
        :glasscutting2_thickness,
        :glasscutting2_color,
        :price,
        :_destroy
      ]
    )
    
    # Procesar manualmente los parámetros anidados para asegurarnos de que se incluyan
    if params[:project][:glasscuttings_attributes].present?
      permitted_params[:glasscuttings_attributes] = params[:project][:glasscuttings_attributes].permit!
    end
    
    if params[:project][:dvhs_attributes].present?
      permitted_params[:dvhs_attributes] = params[:project][:dvhs_attributes].permit!
    end
    
    Rails.logger.info "Parámetros permitidos: #{permitted_params.inspect}"
    permitted_params
  end
end
