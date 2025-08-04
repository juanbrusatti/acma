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
    @project = Project.new
    # @project.glasscuttings.build
    # @project.dvhs.build
  end

  def create
    @project = Project.new(project_params)
    puts project_params.inspect
    
    if @project.save
      redirect_to projects_path, notice: "Proyecto creado exitosamente."
    else
      puts @project.errors.full_messages
      render :new, status: :unprocessable_entity
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
    if @project.update(project_params)
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
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
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
        render pdf: "proyecto_#{@project.id }_#{@project.name}",
               template: "projects/pdf",
               layout: "pdf",
               enable_local_file_access: true,
               margin: { top: 10, bottom: 10, left: 10, right: 10 },
               disable_smart_shrinking: true,
               javascript_delay: 5000,
               timeout: 120
      end
      format.html { redirect_to project_path(@project) }
    end
  end
  def preview_pdf
    begin
      # Construir un objeto Project en memoria con los datos recibidos (sin strong params, solo para preview)
      data = params.to_unsafe_h[:project]
      @project = Project.new(data)
      # Calcular el precio manualmente para cada vidrio
      @project.glasscuttings.each do |glass|
        price_record = GlassPrice.find_by(glass_type: glass.glass_type, thickness: glass.thickness, color: glass.color)
        if price_record && price_record.price_m2.present? && glass.height.present? && glass.width.present?
          area_m2 = (glass.height.to_f / 1000) * (glass.width.to_f / 1000)
          glass.price = (area_m2 * price_record.price_m2).round(2)
        else
          glass.price = nil
        end
      end
      # Calcular el total y el IVA después de inicializar y calcular los precios
      if @project && @project.respond_to?(:glasscuttings) && @project.respond_to?(:dvhs)
        total = @project.glasscuttings.sum { |g| g.price.to_f } + @project.dvhs.sum { |d| d.price.to_f }
        iva = (total * 0.21).round(2)
        @project.define_singleton_method(:total) { price_total }
        @project.define_singleton_method(:iva) { iva }
      end
      respond_to do |format|
        format.pdf do
          response.headers['Content-Disposition'] = "attachment; filename=proyecto_preview.pdf"
          render pdf: "proyecto_preview",
                 template: "projects/pdf",
                 layout: "pdf",
                 enable_local_file_access: true,
                 margin: { top: 10, bottom: 10, left: 10, right: 10 },
                 disable_smart_shrinking: true,
                 javascript_delay: 5000,
                 timeout: 120
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

  def project_params
    params.require(:project).permit(
      :name,
      :phone,
      :address,
      :delivery_date,
      :description,
      :status,
      :price,
      :price_without_iva,
      glasscuttings_attributes: [ :id, :glass_type, :thickness, :height, :width, :color, :typology, :price ],
      dvhs_attributes: [
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
        :price
      ]
    )
  end
end
