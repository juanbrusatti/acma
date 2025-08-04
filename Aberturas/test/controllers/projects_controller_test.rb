require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    # Crear algunos glasscuttings y dvhs para el proyecto de prueba
    @project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "5mm",
      height: 1000,
      width: 800,           
      color: "INC",
      location: "DINTEL",
      price: 150.00
    )
    
    @project.dvhs.create!(
      innertube: "DVH Standard",
      location: "Puerta principal",
      height: 2000,
      width: 900,
      glasscutting1_type: "FLO",
      glasscutting1_thickness: "5mm",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "4+4",
      glasscutting2_color: "GRS",
      price: 300.00
    )
  end

  test "should generate PDF for existing project" do
    get project_path(@project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert_match /attachment; filename=proyecto_#{@project.id}\.pdf/, response.headers['Content-Disposition']
    
    # Verificar que el PDF no esté vacío
    assert response.body.present?
    assert response.body.length > 0
    
    # Verificar que el contenido comience con el header PDF
    assert response.body.start_with?("%PDF")
  end

  test "should handle PDF generation error gracefully" do
    # Simular un error en la generación del PDF
    Project.any_instance.stubs(:name).raises(StandardError, "Test error")
    
    get project_path(@project, format: :pdf)
    
    assert_response :internal_server_error
    assert_match /Error generando PDF/, response.body
  end

  test "should redirect to project page when requesting PDF with HTML format" do
    get project_path(@project, format: :html)
    
    assert_response :success
    assert_template :show
  end

  test "should generate preview PDF with project data" do
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
            location: "Ventana test"
          }
        },
        dvhs_attributes: {
          "0" => {
            innertube: "DVH Test",
            location: "Puerta test",
            height: "2100",
            width: "900",
            glasscutting1_type: "FLO",
            glasscutting1_thickness: "5mm",
            glasscutting1_color: "INC",
            glasscutting2_type: "LAM",
            glasscutting2_thickness: "4+4",
            glasscutting2_color: "GRS"
          }
        }
      }
    }

    post preview_pdf_projects_path(project_params), params: project_params
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert_match /attachment; filename=proyecto_preview\.pdf/, response.headers['Content-Disposition']
    
    # Verificar que el PDF no esté vacío
    assert response.body.present?
    assert response.body.length > 0
    
    # Verificar que el contenido comience con el header PDF
    assert response.body.start_with?("%PDF")
  end

  test "should handle preview PDF generation error gracefully" do
    # Enviar datos inválidos que causen error
    invalid_params = {
      project: {
        name: nil,
        glasscuttings_attributes: {
          "0" => {
            glass_type: nil,
            thickness: "invalid"
          }
        }
      }
    }

    post preview_pdf_projects_path, params: invalid_params
    
    # El controlador debería manejar el error y devolver un mensaje de error
    assert_response :internal_server_error
    assert_match /Error generando PDF/, response.body
  end

  test "PDF should contain project information" do
    get project_path(@project, format: :pdf)
    
    assert_response :success
    
    # Para un test más robusto, podríamos usar una gema como pdf-reader
    # para verificar el contenido del PDF, pero por ahora verificamos
    # que se genere correctamente
    assert response.body.present?
    assert_equal "application/pdf", response.content_type
  end

  test "should set correct PDF headers and options" do
    get project_path(@project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    
    # Verificar que se establezca el Content-Disposition correcto
    expected_filename = "proyecto_#{@project.id}.pdf"
    assert_match /attachment; filename=#{Regexp.escape(expected_filename)}/, response.headers['Content-Disposition']
  end

  test "should generate PDF with project data and glasscuttings" do
    # Agregar más datos de prueba
    @project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "4+4",
      height: 1500,
      width: 1200,
      color: "GRS",
      location: "JAMBA_I",
      price: 200.00
    )

    get project_path(@project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    
    # Verificar que el PDF contenga el header correcto
    assert response.body.start_with?("%PDF")
    
    # Verificar que el PDF tenga un tamaño razonable (más de 1KB)
    assert response.body.length > 1024, "PDF should be larger than 1KB"
  end

  test "should generate PDF with DVH data" do
    # Agregar más DVH data
    @project.dvhs.create!(
      innertube: "DVH Premium",
      location: "Ventana lateral",
      height: 1800,
      width: 1000,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "4+4",
      glasscutting1_color: "GRS",
      glasscutting2_type: "FLO",
      glasscutting2_thickness: "5mm",
      glasscutting2_color: "INC",
      price: 450.00
    )

    get project_path(@project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "should handle PDF generation with missing banner image gracefully" do
    # Este test verifica el problema mencionado en la memoria sobre banner.png
    # Temporalmente renombrar el archivo banner.png si existe
    banner_path = Rails.root.join('public', 'banner.png')
    backup_path = Rails.root.join('public', 'banner_backup.png')
    
    banner_exists = File.exist?(banner_path)
    File.rename(banner_path, backup_path) if banner_exists
    
    begin
      get project_path(@project, format: :pdf)
      
      # El PDF debería generarse aunque falte la imagen
      # (dependiendo de la configuración de wkhtmltopdf)
      assert_response :success
      assert_equal "application/pdf", response.content_type
    ensure
      # Restaurar el archivo si existía
      File.rename(backup_path, banner_path) if banner_exists && File.exist?(backup_path)
    end
  end

  test "should generate PDF with empty glasscuttings and dvhs" do
    # Crear un proyecto sin glasscuttings ni dvhs
    empty_project = Project.create!(
      name: "Proyecto Vacío",
      phone: "987654321",
      address: "Dirección vacía",
      description: "Proyecto sin elementos",
      status: "Pendiente"
    )

    get project_path(empty_project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
    
    # Limpiar
    empty_project.destroy
  end

  test "should handle PDF generation with special characters in project data" do
    # Crear proyecto con caracteres especiales
    special_project = Project.create!(
      name: "Proyecto con Ñoño & Símbolos <>",
      phone: "+54 (011) 1234-5678",
      address: "Calle Ñandú 123, 1° Piso 'A'",
      description: "Descripción con acentos: ñáéíóú & símbolos <>&",
      status: "En Proceso"
    )

    special_project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "5mm",
      height: 1000,
      width: 800,
      color: "INC",
      location: "JAMBA_D",
      price: 150.00
    )

    get project_path(special_project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
    
    # Limpiar
    special_project.destroy
  end

  test "should generate PDF with large amounts of data" do
    # Crear muchos glasscuttings para probar performance
    20.times do |i|
      @project.glasscuttings.create!(
        glass_type: ["FLO", "LAM", "COL"].sample,
        thickness: ["3+3", "4+4", "5+5", "5mm"].sample,
        height: rand(800..2000),
        width: rand(600..1500),
        color: ["INC", "STB", "GRS", "BRC"].sample,
        location: ["DINTEL", "JAMBA_I", "JAMBA_D", "UMBRAL"].sample,
        price: rand(100.0..500.0).round(2)
      )
    end

    get project_path(@project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
    
    # El PDF debería ser considerablemente más grande
    assert response.body.length > 5000, "PDF with large data should be substantial"
  end

  test "should handle concurrent PDF generation requests" do
    # Simular múltiples requests concurrentes
    threads = []
    results = []
    
    3.times do
      threads << Thread.new do
        get project_path(@project, format: :pdf)
        results << {
          status: response.status,
          content_type: response.content_type,
          body_size: response.body.length
        }
      end
    end
    
    threads.each(&:join)
    
    # Todos los requests deberían ser exitosos
    results.each do |result|
      assert_equal 200, result[:status]
      assert_equal "application/pdf", result[:content_type]
      assert result[:body_size] > 0
    end
  end

  private
    
  def preview_pdf_projects_path(params = {})
    "/projects/preview_pdf"
  end
end
