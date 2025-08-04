require "test_helper"

class PdfGenerationTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "5mm",
      height: 1000,
      width: 800,
      color: "INC",
      location: "Ventana principal",
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

  test "PDF generation workflow from project show to download" do
    # Simular el flujo completo de un usuario
    get project_path(@project)
    assert_response :success
    
    # Verificar que el link de PDF esté presente
    assert_select "a[href=?]", project_path(@project, format: :pdf)
    
    # Generar el PDF
    get project_path(@project, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type
    
    # Verificar headers de descarga
    assert_match /attachment/, response.headers['Content-Disposition']
    assert_match /proyecto_#{@project.id}\.pdf/, response.headers['Content-Disposition']
  end

  test "PDF template rendering with wicked_pdf configuration" do
    get project_path(@project, format: :pdf)
    
    assert_response :success
    
    # Verificar que el PDF se generó con wicked_pdf
    assert response.body.start_with?("%PDF")
    
    # Verificar que el PDF contiene metadatos básicos
    pdf_content = response.body
    assert pdf_content.include?("PDF"), "Should contain PDF metadata"
    
    # El PDF debería tener un tamaño mínimo razonable
    assert pdf_content.length > 2048, "PDF should be at least 2KB"
  end

  test "PDF generation with different project states" do
    # Test con proyecto en diferentes estados
    states = ["Pendiente", "En Progreso", "Completado", "Cancelado"]
    
    states.each do |state|
      @project.update!(status: state)
      
      get project_path(@project, format: :pdf)
      assert_response :success, "Should generate PDF for status: #{state}"
      assert_equal "application/pdf", response.content_type
    end
  end

  test "PDF generation performance with timeout handling" do
    # Crear un proyecto con muchos datos para probar performance
    large_project = Project.create!(
      name: "Proyecto Grande",
      phone: "123456789",
      address: "Dirección de prueba",
      description: "Proyecto con muchos elementos para probar performance",
      status: "Pendiente"
    )

    # Crear 50 glasscuttings
    50.times do |i|
      large_project.glasscuttings.create!(
        glass_type: ["FLO", "LAM", "TEM"].sample,
        thickness: ["4mm", "5mm", "6mm"].sample,
        height: rand(800..2000),
        width: rand(600..1500),
        color: ["INC", "GRS", "BRO"].sample,
        location: "Ubicación #{i + 1}",
        price: rand(100.0..500.0).round(2)
      )
    end

    # Medir tiempo de generación
    start_time = Time.current
    get project_path(large_project, format: :pdf)
    generation_time = Time.current - start_time
    
    assert_response :success
    assert generation_time < 30.seconds, "PDF generation should complete within 30 seconds"
    
    # Limpiar
    large_project.destroy
  end

  test "PDF accessibility and encoding" do
    # Crear proyecto con caracteres UTF-8 diversos
    utf8_project = Project.create!(
      name: "Proyecto UTF-8: ñáéíóú ÑÁÉÍÓÚ çüß",
      phone: "+54 (011) 1234-5678",
      address: "Calle Ñandú 123, Piso 1° 'A' & 'B'",
      description: "Descripción con emojis: 🏠 🪟 🚪 y símbolos: €$£¥",
      status: "En Progreso"
    )

    utf8_project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "5mm",
      height: 1000,
      width: 800,
      color: "INC",
      location: "Ventana 'principal' & secundaria",
      price: 150.00
    )

    get project_path(utf8_project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    
    # El PDF debería manejar correctamente los caracteres UTF-8
    assert response.body.start_with?("%PDF")
    
    # Limpiar
    utf8_project.destroy
  end

  test "PDF generation error recovery and logging" do
    # Simular error en el template
    original_name = @project.name
    @project.update!(name: nil)
    
    get project_path(@project, format: :pdf)
    
    # Dependiendo de la configuración, podría ser success con PDF vacío o error
    assert_includes [200, 500], response.status
    
    if response.status == 500
      assert_match /Error generando PDF/, response.body
    else
      # Si es 200, debería ser un PDF válido
      assert_equal "application/pdf", response.content_type
    end
    
    # Restaurar
    @project.update!(name: original_name)
  end

  test "PDF template asset handling" do
    # Verificar que el template maneja correctamente los assets
    get project_path(@project, format: :pdf)
    
    assert_response :success
    
    # El PDF debería generarse incluso si hay problemas con assets
    # (esto es importante para el problema del banner.png mencionado en la memoria)
    assert response.body.start_with?("%PDF")
    assert response.body.length > 1024
  end

  test "PDF generation with malformed data" do
    # Crear glasscutting con datos límite
    @project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "999mm", # Valor inusual
      height: 0, # Valor límite
      width: 99999, # Valor muy grande
      color: "INC",
      location: "A" * 255, # String muy largo
      price: 999999.99 # Precio muy alto
    )

    get project_path(@project, format: :pdf)
    
    # Debería manejar gracefully los datos malformados
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "PDF generation with nil and empty values" do
    # Crear glasscutting con valores nulos/vacíos
    @project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "",
      height: nil,
      width: nil,
      color: "",
      location: nil,
      price: nil
    )

    get project_path(@project, format: :pdf)
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  private

  def assert_pdf_valid(response_body)
    assert response_body.start_with?("%PDF"), "Response should be a valid PDF"
    assert response_body.include?("%%EOF"), "PDF should have proper ending"
    assert response_body.length > 1024, "PDF should have substantial content"
  end
end
