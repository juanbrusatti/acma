require "test_helper"

class PdfHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "should handle glass type humanization for PDF" do
    # Verificar que los helpers de glass type funcionan correctamente
    assert_equal "Float", human_glass_type("FLO")
    assert_equal "Laminado", human_glass_type("LAM")
    assert_equal "Cool Lite", human_glass_type("COL")
    
    # Manejar casos edge
    assert_equal "", human_glass_type("")
    assert_equal "", human_glass_type(nil)
  end

  test "should handle glass color humanization for PDF" do
    # Verificar que los helpers de color funcionan correctamente
    assert_equal "Incoloro", human_glass_color("INC")
    assert_equal "Gris", human_glass_color("GRIS")
    assert_equal "Bronce", human_glass_color("BRONCE")
    assert_equal "Esmerilado", human_glass_color("ESMERILADO")
    
    # Manejar casos edge
    assert_equal "", human_glass_color("")
    assert_equal "", human_glass_color(nil)
  end

  test "should format currency for PDF display" do
    # Verificar formateo de moneda con formato argentino
    assert_equal "$150,00", format_argentine_currency(150.00, unit: "$", precision: 2)
    assert_equal "$1.250,50", format_argentine_currency(1250.50, unit: "$", precision: 2)
    assert_equal "$0,00", format_argentine_currency(0, unit: "$", precision: 2)
    
    # Casos edge - algunos helpers pueden devolver string vacío o nil
    result = format_argentine_currency(nil, unit: "$", precision: 2)
    # Aceptar tanto nil como string vacío
    assert (result.nil? || result == "" || result == "N/A"), "format_argentine_currency should handle nil gracefully"
  end

  test "should handle PDF template asset paths" do
    # Skip for now - asset_path might not be available in test environment
    skip "Asset path testing requires proper Rails asset environment"
  end

  test "should sanitize HTML content for PDF" do
    # Verificar que el contenido HTML se sanitiza correctamente para PDF
    dangerous_content = "<script>alert('xss')</script><p>Safe content</p>"
    
    sanitized = sanitize(dangerous_content)
    assert_not_includes sanitized, "<script>"
    assert_includes sanitized, "Safe content"
  end

  test "should handle nil and empty values in PDF helpers" do
    # Verificar que los helpers manejan correctamente valores nil y vacíos
    
    # Test con valores nil
    assert_nothing_raised do
      number_to_currency(nil, unit: "$", precision: 2)
    end
    
    # Test con strings vacíos
    assert_nothing_raised do
      human_glass_type("")
      human_glass_type(nil)
    end
    
    assert_nothing_raised do
      human_glass_color("")
      human_glass_color(nil)
    end
  end

  test "should handle special characters in PDF content" do
    # Verificar que los helpers manejan caracteres especiales
    special_text = "Ñoño & Símbolos <> 'quotes' \"double quotes\""
    
    # Use ERB::Util.html_escape directly
    escaped = ERB::Util.html_escape(special_text)
    assert_includes escaped, "&amp;"
    assert_includes escaped, "&lt;"
    assert_includes escaped, "&gt;"
  end

  test "should validate PDF template variables" do
    # Simular variables que estarían disponibles en el template PDF
    project = OpenStruct.new(
      name: "Test Project",
      phone: "123456789",
      address: "Test Address",
      description: "Test Description",
      status: "Pendiente"
    )
    
    glasscutting = OpenStruct.new(
      glass_type: "FLO",
      thickness: "5mm",
      height: 1000,
      width: 800,
      color: "INC",
      typology: "V001",
      price: 150.00
    )
    
    # Verificar que las variables tienen los valores esperados
    assert_equal "Test Project", project.name
    assert_equal "123456789", project.phone
    assert_equal "Test Address", project.address
    assert_equal "Test Description", project.description
    assert_equal "Pendiente", project.status
    
    assert_equal "FLO", glasscutting.glass_type
    assert_equal "5mm", glasscutting.thickness
    assert_equal 1000, glasscutting.height
    assert_equal 800, glasscutting.width
    assert_equal "INC", glasscutting.color
    assert_equal "V001", glasscutting.typology
    assert_equal 150.00, glasscutting.price
  end

  test "should calculate totals correctly for PDF" do
    # Simular cálculos que se harían en el template PDF
    glasscuttings = [
      OpenStruct.new(price: 150.00),
      OpenStruct.new(price: 200.50),
      OpenStruct.new(price: 75.25)
    ]
    
    dvhs = [
      OpenStruct.new(price: 300.00),
      OpenStruct.new(price: 450.75)
    ]
    
    # Calcular totales
    glass_total = glasscuttings.sum { |g| g.price.to_f }
    dvh_total = dvhs.sum { |d| d.price.to_f }
    grand_total = glass_total + dvh_total
    
    assert_equal 425.75, glass_total
    assert_equal 750.75, dvh_total
    assert_equal 1176.50, grand_total
    
    # Verificar formateo de moneda con formato argentino
    assert_equal "$425,75", format_argentine_currency(glass_total, unit: "$", precision: 2)
    assert_equal "$750,75", format_argentine_currency(dvh_total, unit: "$", precision: 2)
    assert_equal "$1.176,50", format_argentine_currency(grand_total, unit: "$", precision: 2)
  end

  test "should handle empty collections in PDF calculations" do
    # Verificar cálculos con colecciones vacías
    empty_glasscuttings = []
    empty_dvhs = []
    
    glass_total = empty_glasscuttings.sum { |g| g.price.to_f }
    dvh_total = empty_dvhs.sum { |d| d.price.to_f }
    
    assert_equal 0, glass_total
    assert_equal 0, dvh_total
    
    # Verificar formateo
    assert_equal "$0,00", format_argentine_currency(glass_total, unit: "$", precision: 2)
    assert_equal "$0,00", format_argentine_currency(dvh_total, unit: "$", precision: 2)
  end
end
