require "application_system_test_case"

class ProjectEditFunctionalityTest < ApplicationSystemTestCase
  test "puede editar un proyecto existente y ver los vidrios precargados" do
    # Crear un proyecto con vidrios para testing
    project = Project.create!(
      name: "Proyecto Test",
      description: "Descripción de prueba",
      phone: "123456789",
      address: "Dirección de prueba",
      status: "Pendiente"
    )
    
    # Crear algunos vidrios simples para el proyecto
    glasscutting1 = project.glasscuttings.create!(
      typology: "V1",
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      height: 1000,
      width: 1000,
      price: 150.0
    )
    
    glasscutting2 = project.glasscuttings.create!(
      typology: "V2",
      glass_type: "FLO",
      thickness: "4+4",
      color: "STB",
      height: 800,
      width: 1200,
      price: 200.0
    )
    
    # Crear un DVH para el proyecto
    dvh = project.dvhs.create!(
      typology: "V3",
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
    
    # Verificar que los vidrios simples estén precargados
    assert_selector "#glasscuttings-table-body tr", count: 2
    assert_selector "#glasscuttings-table-body td", text: "V1"
    assert_selector "#glasscuttings-table-body td", text: "V2"
    assert_selector "#glasscuttings-table-body td", text: "LAM"
    assert_selector "#glasscuttings-table-body td", text: "FLO"
    
    # Verificar que los DVHs estén precargados
    assert_selector "#dvhs-table-body tr", count: 1
    assert_selector "#dvhs-table-body td", text: "V3"
    assert_selector "#dvhs-table-body td", text: "12"
    
    # Verificar que los botones de eliminar estén presentes
    assert_selector ".delete-glasscutting", count: 2
    assert_selector ".delete-dvh", count: 1
    
    # Verificar que los botones de agregar estén presentes
    assert_selector "#add-glasscutting", text: "Agregar vidrio simple"
    assert_selector "#add-dvh", text: "Agregar DVH"
  end
  
  test "puede eliminar vidrios existentes en la edición" do
    # Crear un proyecto con vidrios
    project = Project.create!(
      name: "Proyecto Test Eliminar",
      description: "Descripción de prueba",
      phone: "123456789",
      address: "Dirección de prueba",
      status: "Pendiente"
    )
    
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
    
    # Verificar que el vidrio esté presente
    assert_selector "#glasscuttings-table-body tr", count: 1
    
    # Hacer clic en el botón de eliminar
    find(".delete-glasscutting").click
    
    # Verificar que el vidrio se haya ocultado (marcado para destrucción)
    assert_selector "#glasscuttings-table-body tr", count: 0, visible: true
    
    # Verificar que aparezca el mensaje de estado vacío
    assert_selector "div", text: "No hay vidrios simples cargados"
  end
  
  test "puede agregar nuevos vidrios en la edición" do
    # Crear un proyecto vacío
    project = Project.create!(
      name: "Proyecto Test Agregar",
      description: "Descripción de prueba",
      phone: "123456789",
      address: "Dirección de prueba",
      status: "Pendiente"
    )
    
    # Visitar la página de edición
    visit edit_project_path(project)
    
    # Verificar que no hay vidrios inicialmente
    assert_selector "div", text: "No hay vidrios simples cargados"
    
    # Hacer clic en agregar vidrio
    find("#add-glasscutting").click
    
    # Verificar que aparezca el formulario de vidrio
    assert_selector ".glasscutting-fields"
    
    # Llenar el formulario
    within all(".glasscutting-fields").last do
      find(".glass-type-select").find(:option, "LAM").select_option
      assert_selector ".glass-thickness-select option", text: "3+3", wait: 2
      find(".glass-thickness-select").find(:option, "3+3").select_option
      assert_selector ".glass-color-select option", text: "INC", wait: 2
      find(".glass-color-select").find(:option, "INC").select_option
      fill_in "project[glasscuttings_attributes][][height]", with: 1000
      fill_in "project[glasscuttings_attributes][][width]", with: 1000
      click_button "Confirmar"
    end
    
    # Verificar que el vidrio se haya agregado a la tabla
    assert_selector "#glasscuttings-table-body tr", count: 1
    assert_selector "#glasscuttings-table-body td", text: "LAM"
    assert_selector "#glasscuttings-table-body td", text: "3+3"
    assert_selector "#glasscuttings-table-body td", text: "INC"
  end

  test "puede eliminar DVHs existentes en la edición" do
    # Crear un proyecto con DVH
    project = Project.create!(
      name: "Proyecto Test Eliminar DVH",
      description: "Descripción de prueba",
      phone: "123456789",
      address: "Dirección de prueba",
      status: "Pendiente"
    )
    
    dvh = project.dvhs.create!(
      typology: "V1",
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
    
    # Verificar que el DVH esté presente
    assert_selector "#dvhs-table-body tr", count: 1
    
    # Hacer clic en el botón de eliminar
    find(".delete-dvh").click
    
    # Verificar que el DVH se haya ocultado (marcado para destrucción)
    assert_selector "#dvhs-table-body tr", count: 0, visible: true
  end


end
