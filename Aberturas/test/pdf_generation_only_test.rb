require "test_helper"

class PdfGenerationOnlyTest < ActionDispatch::IntegrationTest
  setup do
    # Crear un proyecto válido directamente sin usar fixtures
    @project = Project.create!(
      name: "Proyecto PDF Test",
      phone: "123456789",
      address: "Dirección de prueba",
      description: "Proyecto para tests de PDF",
      status: "Pendiente"
    )
    
    # Crear glasscutting válido
    @project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "5mm",
      height: 1000,
      width: 800,
      color: "INC",
      typology: "V001",
      price: 150.00
    )
  end

  teardown do
    # Limpiar después de cada test
    @project&.destroy
  end

  test "should generate PDF for existing project" do
    get "/projects/#{@project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert_match /filename.*proyecto_#{@project.id}.*\.pdf/, response.headers['Content-Disposition']
    
    # Verificar que el PDF no esté vacío
    assert response.body.present?
    assert response.body.length > 0
    
    # Verificar que el contenido comience con el header PDF
    assert response.body.start_with?("%PDF")
  end

  test "should generate PDF with project data" do
    get "/projects/#{@project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    
    # Verificar que el PDF contenga el header correcto
    assert response.body.start_with?("%PDF")
    
    # Verificar que el PDF tenga un tamaño razonable (más de 1KB)
    assert response.body.length > 1024, "PDF should be larger than 1KB"
  end

  test "should handle PDF generation with empty glasscuttings" do
    # Crear un proyecto sin glasscuttings
    empty_project = Project.create!(
      name: "Proyecto Vacío",
      phone: "987654321",
      address: "Dirección vacía",
      description: "Proyecto sin elementos",
      status: "Pendiente"
    )

    get "/projects/#{empty_project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
    
    # Limpiar
    empty_project.destroy
  end

  test "should set correct PDF headers and filename" do
    get "/projects/#{@project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    
    # Verificar que se establezca el Content-Disposition correcto
    expected_filename = "proyecto_#{@project.id}"
    assert_match /filename.*#{Regexp.escape(expected_filename)}.*\.pdf/, response.headers['Content-Disposition']
  end

  test "should generate preview PDF with valid data" do
    project_params = {
      project: {
        name: "Proyecto Preview Test",
        phone: "123456789",
        address: "Dirección de prueba",
        description: "Descripción de prueba",
        status: "Pendiente",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "FLO",
            thickness: "5mm",
            height: "1200",
            width: "800",
            color: "INC",
            typology: "V001"
          }
        }
      }
    }

    post "/projects/preview_pdf", params: project_params, headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert_match /filename.*proyecto_preview.*\.pdf/, response.headers['Content-Disposition']
    
    # Verificar que el PDF no esté vacío
    assert response.body.present?
    assert response.body.length > 0
    
    # Verificar que el contenido comience con el header PDF
    assert response.body.start_with?("%PDF")
  end

  test "should handle PDF generation with special characters" do
    # Crear proyecto con caracteres especiales
    special_project = Project.create!(
      name: "Proyecto con Ñoño & Símbolos",
      phone: "+54 (011) 1234-5678",
      address: "Calle Ñandú 123",
      description: "Descripción con acentos: ñáéíóú",
      status: "Pendiente"
    )

    special_project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "5mm",
      height: 1000,
      width: 800,
      color: "INC",
      typology: "V001",
      price: 150.00
    )

    get "/projects/#{special_project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
    
    # Limpiar
    special_project.destroy
  end

  test "should handle PDF generation with multiple glasscuttings" do
    # Agregar más glasscuttings
    @project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "4+4",
      height: 1500,
      width: 1200,
      color: "GRS",
      typology: "V002",
      price: 200.00
    )

    @project.glasscuttings.create!(
      glass_type: "COL",
      thickness: "3+3",
      height: 800,
      width: 600,
      color: "STB",
      typology: "V003",
      price: 100.00
    )

    get "/projects/#{@project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
    
    # El PDF debería ser más grande con más datos
    assert response.body.length > 2000, "PDF with multiple glasscuttings should be larger"
  end

  test "should validate PDF structure" do
    get "/projects/#{@project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    
    pdf_content = response.body
    
    # Validaciones básicas de estructura PDF
    assert pdf_content.start_with?("%PDF"), "Should start with PDF header"
    
    # El PDF debería tener objetos
    assert pdf_content.include?("obj"), "Should contain PDF objects"
    
    # Verificar tamaño mínimo para contenido sustancial
    assert pdf_content.length > 1000, "PDF should have substantial content"
  end

  test "should handle banner image gracefully" do
    # Este test verifica el problema mencionado en la memoria sobre banner.png
    # Temporalmente renombrar el archivo banner.png si existe
    banner_path = Rails.root.join('public', 'banner.png')
    backup_path = Rails.root.join('public', 'banner_backup.png')
    
    banner_exists = File.exist?(banner_path)
    File.rename(banner_path, backup_path) if banner_exists
    
    begin
      get "/projects/#{@project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
      
      # El PDF debería generarse aunque falte la imagen
      assert_response :success
      assert_equal "application/pdf", response.content_type
      assert response.body.start_with?("%PDF")
    ensure
      # Restaurar el archivo si existía
      File.rename(backup_path, banner_path) if banner_exists && File.exist?(backup_path)
    end
  end

  test "should generate PDF with performance test" do
    # Crear varios glasscuttings para probar performance
    5.times do |i|
      @project.glasscuttings.create!(
        glass_type: ["FLO", "LAM", "COL"].sample,
        thickness: ["3+3", "4+4", "5+5", "5mm"].sample,
        height: rand(800..2000),
        width: rand(600..1500),
        color: ["INC", "STB", "GRS", "BRC"].sample,
        typology: ["V001", "V002", "V003", "V004"].sample,
        price: rand(100.0..500.0).round(2)
      )
    end

    start_time = Time.current
    get "/projects/#{@project.id}/pdf", headers: { 'Accept' => 'application/pdf' }
    generation_time = Time.current - start_time
    
    assert_response :success
    assert generation_time < 10.seconds, "PDF generation should complete within 10 seconds"
    assert_equal "application/pdf", response.content_type
    assert response.body.length > 3000, "PDF with multiple glasscuttings should be substantial"
  end
end
