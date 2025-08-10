require 'test_helper'

class PartialsRenderingTest < ActionDispatch::IntegrationTest
  test "los partials de proyectos se renderizan en la vista de nuevo proyecto" do
    get new_project_path
    assert_response :success
    # Verifica que el partial de vidrios simples se renderiza
    assert_select 'h2', text: 'Vidrios simples'
    assert_select 'button#add-glasscutting', text: 'Agregar vidrio simple'
    # Verifica que el partial de DVH se renderiza
    assert_select 'h2', text: 'DVH'
    assert_select 'button#add-dvh', text: 'Agregar DVH'
    # Verifica que existen los selects clave
    assert_select 'select.glass-type-select'
    assert_select 'select.glasscutting1-type-select'
    assert_select 'select.glasscutting2-type-select'
  end
end 