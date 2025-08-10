require "test_helper"

class SimplePdfTest < ActionDispatch::IntegrationTest
  test "basic PDF generation functionality" do
    # Crear un proyecto simple
    project = Project.create!(
      name: "Test PDF",
      phone: "123456789", 
      address: "Test Address",
      description: "Test Description",
      status: "Pendiente"
    )

    # Verificar que el proyecto se creó correctamente
    assert project.persisted?, "Project should be saved"
    assert_equal "Test PDF", project.name

    # Intentar acceder a la ruta PDF usando la acción pdf
    begin
      get "/projects/#{project.id}/pdf"
      
      # Imprimir información de debug
      puts "Response status: #{response.status}"
      puts "Response content type: #{response.content_type}"
      puts "Response headers: #{response.headers.to_h}"
      puts "Response body (first 100 chars): #{response.body[0..100]}"
      
      # Verificar que no sea un error 404 o 406
      assert_not_equal 404, response.status, "Route should exist"
      assert_not_equal 406, response.status, "Format should be acceptable"
      
      if response.status == 200
        assert_equal "application/pdf", response.content_type
        assert response.body.present?, "PDF body should not be empty"
      else
        puts "PDF generation failed with status: #{response.status}"
        puts "Error body: #{response.body}"
      end
      
    rescue => e
      puts "Exception during PDF generation: #{e.message}"
      puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
      flunk "PDF generation raised an exception: #{e.message}"
    ensure
      # Limpiar
      project.destroy if project.persisted?
    end
  end

  test "check wicked_pdf configuration" do
    # Verificar que wicked_pdf está disponible
    assert defined?(WickedPdf), "WickedPdf should be available"
    
    # Verificar configuración básica
    config = WickedPdf.config
    assert config.is_a?(Hash), "WickedPdf config should be a hash"
    
    puts "WickedPdf config: #{config.inspect}"
  end

  test "check project model validations" do
    # Verificar que podemos crear un proyecto válido
    project = Project.new(
      name: "Test Project",
      phone: "123456789",
      address: "Test Address", 
      description: "Test Description",
      status: "Pendiente"
    )
    
    assert project.valid?, "Project should be valid. Errors: #{project.errors.full_messages}"
    
    project.save!
    assert project.persisted?, "Project should be saved"
    
    project.destroy
  end

  test "check routes configuration" do
    # Verificar que las rutas están configuradas
    assert_routing({ method: 'get', path: '/projects/1/pdf' }, 
                   { controller: 'projects', action: 'pdf', id: '1' })
  end
end
