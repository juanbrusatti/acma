require 'test_helper'

class ProjectsHelperTest < ActionView::TestCase
  test "pagination_info should return correct pagination text" do
    # Mock de la colección con paginación
    collection = OpenStruct.new(
      current_page: 2,
      per_page: 10,
      total_entries: 35,
      total_pages: 4
    )
    
    assert_equal "Mostrando 11 - 20 de 35 resultados", pagination_info(collection)
  end

  test "pagination_info should return empty string for empty collection" do
    collection = OpenStruct.new(
      total_pages: 0,
      total_entries: 0
    )
    
    assert_equal "", pagination_info(collection)
  end

  test "project_status_color should return correct color class" do
    assert_equal "text-green-600", project_status_color("Terminado")
    assert_equal "text-blue-600", project_status_color("En Proceso")
    assert_equal "text-yellow-600", project_status_color("Pendiente")
    assert_equal "text-gray-600", project_status_color("Otro Estado")
  end

  test "project_status_icon should return correct SVG path" do
    assert_includes project_status_icon("Terminado"), "M22 11.08V12a10 10 0 1 1-5.93-9.14 M22,4 12,14.01 9,11.01"
    assert_includes project_status_icon("En Proceso"), "M12 2v4 M12 18v4 M4.93 4.93l2.83 2.83"
    assert_includes project_status_icon("Pendiente"), "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    assert_includes project_status_icon("Otro"), "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
  end

  test "projects_summary_text should return correct pluralization" do
    assert_equal "1 proyecto", projects_summary_text(1)
    assert_equal "2 proyectos", projects_summary_text(2)
    assert_equal "5 proyectos", projects_summary_text(5)
  end

  test "projects_completed_text should return correct pluralization" do
    assert_equal "1 completado este mes", projects_completed_text(1)
    assert_equal "2 completados este mes", projects_completed_text(2)
    assert_equal "5 completados este mes", projects_completed_text(5)
  end

  test "project_delivery_status should return correct status" do
    # Probar cuando no hay fecha de entrega
    project = OpenStruct.new(
      delivery_date: nil,
      overdue?: false
    )
    assert_equal "Sin fecha", project_delivery_status(project)

    # Proyecto atrasado
    project.delivery_date = Date.yesterday
    project.define_singleton_method(:overdue?) { true }
    assert_equal "Atrasado", project_delivery_status(project)

    # Proyecto con entrega en el futuro
    project.delivery_date = Date.tomorrow
    project.define_singleton_method(:overdue?) { false }
    project.define_singleton_method(:days_until_delivery) { 1 }
    assert_equal "En 1 días", project_delivery_status(project)

    # Proyecto con entrega hoy
    project.define_singleton_method(:days_until_delivery) { 0 }
    assert_equal "Hoy", project_delivery_status(project)

    # Proyecto completado (sin días hasta entrega)
    project.define_singleton_method(:days_until_delivery) { nil }
    assert_equal "Completado", project_delivery_status(project)
  end

  test "project_status_badge_html should return HTML with correct classes" do
    html = project_status_badge_html("Terminado")
    assert_includes html, "bg-green-100"
    assert_includes html, "text-green-700"
    assert_includes html, "Terminado"
  end
end
