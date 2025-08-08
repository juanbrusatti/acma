require "application_system_test_case"

class ProjectEditButtonsTest < ApplicationSystemTestCase
  test "los botones de eliminar están presentes en la página de edición" do
    # Crear un proyecto con vidrios para testing
    project = Project.create!(
      name: "Proyecto Test Botones",
      description: "Descripción de prueba",
      phone: "123456789",
      address: "Dirección de prueba",
      status: "Pendiente"
    )
    
    # Crear un vidrio simple para el proyecto
    glasscutting = project.glasscuttings.create!(
      typology: "V1",
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      height: 1000,
      width: 1000,
      price: 150.0
    )
    
    # Crear un DVH para el proyecto
    dvh = project.dvhs.create!(
      typology: "V2",
      innertube: 12,
      width: 1500,
      height: 1000,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "FLO",
      glasscutting2_thickness: "4+4",
      glasscutting2_color: "STB",
      price: 350.0
    )
    
    # Visitar la página de edición
    visit edit_project_path(project)
    
    # Verificar que los botones de eliminar estén presentes
    assert_selector ".delete-glasscutting", count: 1, text: "Eliminar"
    assert_selector ".delete-dvh", count: 1, text: "Eliminar"
    
    # Verificar que los botones sean visibles y clickeables
    assert_selector ".delete-glasscutting", visible: true
    assert_selector ".delete-dvh", visible: true
    
    # Verificar que los botones tengan el atributo data-id
    assert_selector ".delete-glasscutting[data-id='#{glasscutting.id}']"
    assert_selector ".delete-dvh[data-id='#{dvh.id}']"
  end
  
  test "los botones de eliminar funcionan correctamente" do
    # Crear un proyecto con vidrios para testing
    project = Project.create!(
      name: "Proyecto Test Funcionalidad",
      description: "Descripción de prueba",
      phone: "123456789",
      address: "Dirección de prueba",
      status: "Pendiente"
    )
    
    # Crear un vidrio simple para el proyecto
    glasscutting = project.glasscuttings.create!(
      typology: "V1",
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      height: 1000,
      width: 1000,
      price: 150.0
    )
    
    # Visitar la página de edición
    visit edit_project_path(project)
    
    # Verificar que el vidrio esté presente inicialmente
    assert_selector "#glasscuttings-table-body tr", count: 1
    
    # Verificar que el botón de eliminar esté presente y sea clickeable
    assert_selector ".delete-glasscutting", visible: true
    
    # Hacer clic en el botón de eliminar
    find(".delete-glasscutting").click
    
    # Verificar que el vidrio se haya ocultado (marcado para destrucción)
    # Esperar un poco para que el JavaScript se ejecute
    sleep(1)
    
    # Verificar que la fila esté oculta
    assert_selector "#glasscuttings-table-body tr", count: 0, visible: true
  end
end
