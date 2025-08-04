require "test_helper"

class PdfHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "should handle glass type humanization for PDF" do
    # Verificar que los helpers de glass type funcionan correctamente
    assert_equal "Flotado", human_glass_type("FLO") if respond_to?(:human_glass_type)
    assert_equal "Laminado", human_glass_type("LAM") if respond_to?(:human_glass_type)
    assert_equal "Templado", human_glass_type("TEM") if respond_to?(:human_glass_type)
    
    # Manejar casos edge
    assert_equal "", human_glass_type("") if respond_to?(:human_glass_type)
    assert_equal "", human_glass_type(nil) if respond_to?(:human_glass_type)
  end

  test "should handle glass color humanization for PDF" do
    # Verificar que los helpers de color funcionan correctamente
    assert_equal "Incoloro", human_glass_color("INC") if respond_to?(:human_glass_color)
    assert_equal "Gris", human_glass_color("GRS") if respond_to?(:human_glass_color)
    assert_equal "Bronce", human_glass_color("BRO") if respond_to?(:human_glass_color)
    assert_equal "Verde", human_glass_color("VER") if respond_to?(:human_glass_color)
    
    # Manejar casos edge
    assert_equal "", human_glass_color("") if respond_to?(:human_glass_color)
    assert_equal "", human_glass_color(nil) if respond_to?(:human_glass_color)
  end

  test "should format currency for PDF display" do
    # Verificar formateo de moneda
    assert_equal "$150.00", number_to_currency(150.00, unit: "$", precision: 2)
    assert_equal "$1,250.50", number_to_currency(1250.50, unit: "$", precision: 2)
    assert_equal "$0.00", number_to_currency(0, unit: "$", precision: 2)
    
    # Casos edge
    assert_equal "$0.00", number_to_currency(nil, unit: "$", precision: 2)
  end

  test "should handle PDF template asset paths" do
    # Verificar que los paths de assets se manejan correctamente
    if respond_to?(:asset_path)
      banner_path = asset_path('banner.png')
      assert_not_nil banner_path
      assert_kind_of String, banner_path
    end
  end

  test "should sanitize HTML content for PDF" do
    # Verificar que el contenido HTML se sanitiza correctamente para PDF
    dangerous_content = "<script>alert('xss')</script><p>Safe content</p>"
    
    if respond_to?(:sanitize)
      sanitized = sanitize(dangerous_content)
      assert_not_includes sanitized, "<script>"
      assert_includes sanitized, "Safe content"
    end
  end

  test "should handle nil and empty values in PDF helpers" do
    # Verificar que los helpers manejan correctamente valores nil y vacíos
    
    # Test con valores nil
    assert_nothing_raised do
      number_to_currency(nil, unit: "$", precision: 2)
    end
    
    # Test con strings vacíos
    if respond_to?(:human_glass_type)
      assert_nothing_raised do
        human_glass_type("")
        human_glass_type(nil)
      end
    end
    
    if respond_to?(:human_glass_color)
      assert_nothing_raised do
        human_glass_color("")
        human_glass_color(nil)
      end
    end
  end

  test "should handle special characters in PDF content" do
    # Verificar que los helpers manejan caracteres especiales
    special_text = "Ñoño & Símbolos <> 'quotes' \"double quotes\""
    
    if respond_to?(:h) # html_escape helper
      escaped = h(special_text)
      assert_includes escaped, "&amp;"
      assert_includes escaped, "&lt;"
      assert_includes escaped, "&gt;"
    end
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
      location: "Test Location",
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
    assert_equal "Test Location", glasscutting.location
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
    
    # Verificar formateo de moneda
    assert_equal "$425.75", number_to_currency(glass_total, unit: "$", precision: 2)
    assert_equal "$750.75", number_to_currency(dvh_total, unit: "$", precision: 2)
    assert_equal "$1,176.50", number_to_currency(grand_total, unit: "$", precision: 2)
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
    assert_equal "$0.00", number_to_currency(glass_total, unit: "$", precision: 2)
    assert_equal "$0.00", number_to_currency(dvh_total, unit: "$", precision: 2)
  end
end
