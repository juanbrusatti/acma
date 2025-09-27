require "application_system_test_case"

class ProjectsSearchAndFilterTest < ApplicationSystemTestCase
  setup do
    # Create test projects with different statuses
    @project1 = projects(:one)
    @project2 = projects(:completed_project)
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
    visit projects_path
    
    # Check that all projects are shown initially
    assert_selector "table tbody tr", count: 4
    
    # Filter by 'Pendiente' status
    select "Pendiente", from: "status"
    # The form should auto-submit when status changes (see the onchange in the view)
    # No need to click a button
    
    # Wait for the page to update
    assert_selector "table tbody tr", count: 2, wait: 5  # One from fixture, one created in setup
    assert_text @project1.name
    assert_no_text @project2.name
    assert_no_text @project3.name
    
    # Filter by 'En Proceso' status
    select "En Proceso", from: "status"
    
    # Should show only in-progress projects
    assert_selector "table tbody tr", count: 1, wait: 5
    assert_text @project3.name
    assert_no_text @project1.name
    assert_no_text @project2.name
    
    # Filter by 'Terminado' status
    select "Terminado", from: "status"
    
    # Should show only completed projects
    assert_selector "table tbody tr", count: 1, wait: 5
    assert_text @project2.name
    assert_no_text @project1.name
    assert_no_text @project3.name
    
    # Reset filter
    select "Todos", from: "status"
    
    # Should show all projects again
    assert_selector "table tbody tr", count: 4, wait: 5
  end
  
  test "should search projects by name" do
    visit projects_path
    
    # Initial count of projects
    assert_selector "table tbody tr", count: 4
    
    # Search for a specific project name
    fill_in "search", with: "especial"
    # The form should auto-submit when pressing Enter in the search field
    find_field('search').send_keys(:enter)
    
    # Should show only the matching project
    assert_selector "table tbody tr", count: 1, wait: 5
    assert_text @searchable_project.name
    assert_no_text @project1.name
    assert_no_text @project2.name
    assert_no_text @project3.name
    
    # Clear search by clicking the "Limpiar" button that appears when there's a search
    click_on "Limpiar"
    
    # Should show all projects again
    assert_selector "table tbody tr", count: 4, wait: 5
  end
  
  test "should combine search and status filter" do
    # Create an additional project that matches both search and status
    combined_project = Project.create!(
      name: "Proyecto especial en proceso",
      phone: "555111222",
      status: "En Proceso",
      description: "Este proyecto combina búsqueda y filtro",
      delivery_date: 2.days.from_now
    )
    
    visit projects_path
    
    # Apply search filter
    fill_in "search", with: "especial"
    find_field('search').send_keys(:enter)
    
    # Apply status filter
    select "En Proceso", from: "status"
    
    # Should show only the project that matches both criteria
    assert_selector "table tbody tr", count: 1, wait: 5
    assert_text combined_project.name
    assert_no_text @searchable_project.name
    assert_no_text @project1.name
    assert_no_text @project2.name
    assert_no_text @project3.name
  end
  
  test "should show no results message when no projects match search" do
    visit projects_path
    
    # Search for non-existent project
    fill_in "search", with: "proyecto que no existe"
    find_field('search').send_keys(:enter)
    
    # Should show no results message in the table
    assert_selector "table tbody tr td", text: "No se encontraron proyectos con los filtros aplicados.", wait: 5
  end
end
