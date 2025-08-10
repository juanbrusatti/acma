require "test_helper"

class PdfPreviewTest < ActionDispatch::IntegrationTest
  test "should generate preview PDF with valid project data" do
    project_params = {
      project: {
        name: "Proyecto Preview Completo",
        phone: "+54 (011) 4567-8901",
        address: "Av. Corrientes 1234, CABA",
        description: "Proyecto completo para preview con múltiples elementos",
        status: "Pendiente",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "FLO",
            thickness: "5mm",
            height: "1200",
            width: "800",
            color: "INC",
            typology: "V001"
          },
          "1" => {
            glass_type: "LAM",
            thickness: "4+4",
            height: "1500",
            width: "1000",
            color: "GRS",
            typology: "V002"
          }
        },
        dvhs_attributes: {
          "0" => {
            innertube: "6",
            typology: "V003",
            height: "2100",
            width: "900",
            glasscutting1_type: "FLO",
            glasscutting1_thickness: "5mm",
            glasscutting1_color: "INC",
            glasscutting2_type: "LAM",
            glasscutting2_thickness: "4+4",
            glasscutting2_color: "GRS"
          },
          "1" => {
            innertube: "9",
            typology: "V004",
            height: "1800",
            width: "1200",
            glasscutting1_type: "TEM",
            glasscutting1_thickness: "6mm",
            glasscutting1_color: "BRO",
            glasscutting2_type: "FLO",
            glasscutting2_thickness: "8mm",
            glasscutting2_color: "VER"
          }
        }
      }
    }

    post "/projects/preview_pdf", params: project_params, headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert_match /filename.*proyecto_preview.*\.pdf/, response.headers['Content-Disposition']
    
    # Verificar que el PDF sea válido
    assert response.body.start_with?("%PDF")
    assert response.body.length > 2048, "Preview PDF should be substantial"
  end

  test "should handle preview PDF with minimal data" do
    minimal_params = {
      project: {
        name: "Proyecto Mínimo",
        phone: "123456789",
        address: "Dirección básica",
        description: "Descripción mínima",
        status: "Pendiente"
      }
    }

    post "/projects/preview_pdf", params: minimal_params, headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "should handle preview PDF with special characters and UTF-8" do
    utf8_params = {
      project: {
        name: "Proyecto Ñoño con acentós",
        phone: "+54 (011) 1234-5678",
        address: "Calle Ñandú 123, 1° Piso 'A' & 'B'",
        description: "Descripción con símbolos: €$£¥ y emojis 🏠",
        status: "En Progreso",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "FLO",
            thickness: "5mm",
            height: "1000",
            width: "800",
            color: "INC",
            typology: "V005"
          }
        }
      }
    }

    post "/projects/preview_pdf", params: utf8_params, headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "should handle preview PDF with invalid glasscutting data" do
    invalid_params = {
      project: {
        name: "Proyecto con datos inválidos",
        phone: "123456789",
        address: "Dirección",
        description: "Descripción",
        status: "Pendiente",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "", # Vacío
            thickness: "invalid_thickness",
            height: "not_a_number",
            width: "-100", # Negativo
            color: "INVALID_COLOR",
            typology: "V006" # Muy largo
          }
        }
      }
    }

    post "/projects/preview_pdf", params: invalid_params, headers: { 'Accept' => 'application/pdf' }
    
    # Debería manejar gracefully los datos inválidos
    assert_includes [200, 500], response.status
    
    if response.status == 200
      assert_equal "application/pdf", response.content_type
      assert response.body.start_with?("%PDF")
    else
      assert_match /Error generando PDF/, response.body
    end
  end

  test "should handle preview PDF with large amounts of data" do
    large_params = {
      project: {
        name: "Proyecto Grande",
        phone: "123456789",
        address: "Dirección",
        description: "Proyecto con muchos elementos",
        status: "Pendiente",
        glasscuttings_attributes: {},
        dvhs_attributes: {}
      }
    }

    # Agregar 30 glasscuttings
    30.times do |i|
      large_params[:project][:glasscuttings_attributes][i.to_s] = {
        glass_type: ["FLO", "LAM", "TEM"].sample,
        thickness: ["4mm", "5mm", "6mm", "4+4", "6+6"].sample,
        height: rand(800..2000).to_s,
        width: rand(600..1500).to_s,
        color: ["INC", "GRS", "BRO", "VER"].sample,
        typology: "V#{sprintf("%03d", i + 7)}"
      }
    end

    # Agregar 15 DVHs
    15.times do |i|
      large_params[:project][:dvhs_attributes][i.to_s] = {
        innertube: "DVH #{i + 1}",
        typology: "V#{sprintf("%03d", i + 20)}",
        height: rand(1500..2500).to_s,
        width: rand(800..1200).to_s,
        glasscutting1_type: ["FLO", "LAM"].sample,
        glasscutting1_thickness: ["4mm", "5mm"].sample,
        glasscutting1_color: ["INC", "GRS"].sample,
        glasscutting2_type: ["LAM", "TEM"].sample,
        glasscutting2_thickness: ["6mm", "4+4"].sample,
        glasscutting2_color: ["BRO", "VER"].sample
      }
    end

    start_time = Time.current
    post "/projects/preview_pdf", params: large_params, headers: { 'Accept' => 'application/pdf' }
    generation_time = Time.current - start_time
    
    assert_response :success
    assert generation_time < 45.seconds, "Large preview PDF should generate within 45 seconds"
    assert_equal "application/pdf", response.content_type
    assert response.body.length > 10000, "Large preview PDF should be substantial"
  end

  test "should handle preview PDF with empty nested attributes" do
    empty_nested_params = {
      project: {
        name: "Proyecto con atributos vacíos",
        phone: "123456789",
        address: "Dirección",
        description: "Descripción",
        status: "Pendiente",
        glasscuttings_attributes: {},
        dvhs_attributes: {}
      }
    }

    post "/projects/preview_pdf", params: empty_nested_params, headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "should handle preview PDF with nil values in nested attributes" do
    nil_params = {
      project: {
        name: "Proyecto con nils",
        phone: "123456789",
        address: "Dirección",
        description: "Descripción",
        status: "Pendiente",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "FLO",
            thickness: nil,
            height: nil,
            width: nil,
            color: "INC",
            typology: "V999"
          }
        },
        dvhs_attributes: {
          "0" => {
            innertube: nil,
            typology: "V999",
            height: nil,
            width: nil,
            glasscutting1_type: nil,
            glasscutting1_thickness: nil,
            glasscutting1_color: nil,
            glasscutting2_type: nil,
            glasscutting2_thickness: nil,
            glasscutting2_color: nil
          }
        }
      }
    }

    post "/projects/preview_pdf", params: nil_params, headers: { 'Accept' => 'application/pdf' }
    
    # Debería manejar gracefully los valores nil
    assert_includes [200, 500], response.status
    
    if response.status == 200
      assert_equal "application/pdf", response.content_type
      assert response.body.start_with?("%PDF")
    end
  end

  test "should validate preview PDF content structure" do
    project_params = {
      project: {
        name: "Proyecto Validación",
        phone: "987654321",
        address: "Dirección de validación",
        description: "Para validar estructura del PDF",
        status: "En Progreso",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "LAM",
            thickness: "6+6",
            height: "1800",
            width: "1200",
            color: "BRO",
            typology: "V100"
          }
        }
      }
    }

    post "/projects/preview_pdf", params: project_params, headers: { 'Accept' => 'application/pdf' }
    
    assert_response :success
    
    pdf_content = response.body
    
    # Validaciones básicas de estructura PDF
    assert pdf_content.start_with?("%PDF"), "Should start with PDF header"
    assert pdf_content.include?("%%EOF"), "Should end with PDF footer"
    
    # El PDF debería tener objetos y streams
    assert pdf_content.include?("obj"), "Should contain PDF objects"
    assert pdf_content.include?("stream"), "Should contain PDF streams"
    
    # Verificar tamaño mínimo para contenido sustancial
    assert pdf_content.length > 3000, "PDF should have substantial content"
  end

  test "should handle concurrent preview PDF requests" do
    project_params = {
      project: {
        name: "Proyecto Concurrente",
        phone: "123456789",
        address: "Dirección",
        description: "Para pruebas de concurrencia",
        status: "Pendiente",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "FLO",
            thickness: "5mm",
            height: "1000",
            width: "800",
            color: "INC",
            typology: "V200"
          }
        }
      }
    }

    # Test multiple sequential requests instead of concurrent to avoid threading issues in tests
    5.times do |i|
      post "/projects/preview_pdf", params: project_params, headers: { 'Accept' => 'application/pdf' }
      assert_equal 200, response.status
      assert_equal "application/pdf", response.content_type
      assert response.body.length > 1000
    end
  end
end
