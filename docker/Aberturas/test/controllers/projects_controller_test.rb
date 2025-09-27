require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create test projects with different statuses
    @project1 = projects(:one)  # Pending
    @project2 = projects(:completed_project)  # Terminado
    @project3 = Project.create!(
      name: "Proyecto en proceso",
      phone: "555123456",
      status: "En Proceso",
      description: "Proyecto que está en proceso",
      delivery_date: Date.tomorrow
    )
    
    # Create a project with a unique name for search testing
    @searchable_project = Project.create!(
      name: "Proyecto de búsqueda especial",
      phone: "555987654",
      status: "Pendiente",
      description: "Este proyecto es para probar la búsqueda",
      delivery_date: 1.week.from_now
    )
  end
  
  test "should filter projects by status" do
    # Test filtering by 'Pendiente' status
    get projects_url, params: { status: "Pendiente" }
    assert_response :success
    
    # Should include pending projects
    assert_select 'table tbody tr', { count: 2 }  # One from fixture, one created in setup
    assert_match @project1.name, response.body
    assert_match @searchable_project.name, response.body
    
    # Should not include projects with other statuses
    assert_no_match @project2.name, response.body
    assert_no_match @project3.name, response.body
    
    # Test filtering by 'En Proceso' status
    get projects_url, params: { status: "En Proceso" }
    assert_response :success
    
    assert_select 'table tbody tr', { count: 1 }
    assert_match @project3.name, response.body
    
    # Test filtering by 'Terminado' status
    get projects_url, params: { status: "Terminado" }
    assert_response :success
    
    assert_select 'table tbody tr', { count: 1 }
    assert_match @project2.name, response.body
  end
  
  test "should search projects by name" do
    # Test searching by part of the name
    get projects_url, params: { search: "especial" }
    assert_response :success
    
    # Should include only the matching project
    assert_select 'table tbody tr', { count: 1 }
    assert_match @searchable_project.name, response.body
    
    # Test case-insensitive search
    get projects_url, params: { search: "ESPECIAL" }
    assert_response :success
    assert_select 'table tbody tr', { count: 1 }
    
    # Test search with no results
    get projects_url, params: { search: "proyecto que no existe" }
    assert_response :success
    # Should show the no results message in the table
    assert_select 'table tbody tr td', { text: "No se encontraron proyectos con los filtros aplicados." }
  end
  
  test "should combine search and status filter" do
    # Create a project that would match both filters
    combined_project = Project.create!(
      name: "Proyecto especial en proceso",
      phone: "555111222",
      status: "En Proceso",
      description: "Este proyecto combina búsqueda y filtro",
      delivery_date: 2.days.from_now
    )
    
    # Test with both search and status filters
    get projects_url, params: { 
      search: "especial", 
      status: "En Proceso" 
    }
    
    assert_response :success
    
    # Should include only the project that matches both criteria
    assert_select 'table tbody tr', { count: 1 }
    assert_match combined_project.name, response.body
    assert_no_match @searchable_project.name, response.body
    assert_no_match @project1.name, response.body
    assert_no_match @project2.name, response.body
    assert_no_match @project3.name, response.body
  end
  
  test "should paginate results" do
    # Create enough projects to trigger pagination
    15.times do |i|
      Project.create!(
        name: "Project Pagination #{i}",
        phone: "555000#{i}",
        status: "Pendiente",
        description: "Project for testing pagination",
        delivery_date: 1.week.from_now
      )
    end
    
    # First page should have 10 items (default per_page)
    get projects_url
    assert_response :success
    assert_select 'table tbody tr', { count: 10 }
    
    # Second page should have the remaining items
    get projects_url, params: { page: 2 }
    assert_response :success
    # 4 from setup + 15 created - 10 on first page = 9 on second page
    assert_select 'table tbody tr', { count: 9 }
  end
end
