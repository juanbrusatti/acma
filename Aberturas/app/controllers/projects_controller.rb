class ProjectsController < ApplicationController
  def index
    @projects = Project.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
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
          # Habria que guardar el precio
          render json: {
            success: true,
            project: helpers.project_json_data(@project),
            status_badge_html: helpers.project_status_badge_html(@project.status)
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
      glasscuttings_attributes: [ :id, :glass_type, :thickness, :height, :width, :color, :location, :price ],
      dvhs_attributes: [
        :innertube,
        :location,
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
