class ProjectsController < ApplicationController
  def index
    @projects = Project.all
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = @projects.order(created_at: :desc)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to projects_path, notice: 'Proyecto creado exitosamente.'
    else
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
      redirect_to projects_path, notice: 'Proyecto actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to projects_path, notice: 'Proyecto eliminado exitosamente.'
  end

  private

  def project_params
    params.require(:project).permit(:name, :description, :status, :delivery_date)
  end
end 