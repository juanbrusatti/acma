require 'test_helper'

class DvhTest < ActiveSupport::TestCase
  setup do
    # Usando fixtures en lugar de crear directamente
    @project = projects(:one) # Asegúrate de tener un fixture para Project
  end

  test "requires all mandatory attributes" do
    dvh = Dvh.new
    assert_not dvh.valid?
    assert_includes dvh.errors[:height], "El alto del vidrio no puede estar en blanco"
    assert_includes dvh.errors[:width], "El ancho del vidrio no puede estar en blanco"
    assert_includes dvh.errors[:typology], "La tipología del DVH no puede estar en blanco"
    assert_includes dvh.errors[:innertube], "La cámara del vidrio no es válida"
    assert_includes dvh.errors[:glasscutting1_type], "El tipo de vidrio 1 no puede estar en blanco"
    assert_includes dvh.errors[:glasscutting1_thickness], "El espesor del vidrio 1 no puede estar en blanco"
    assert_includes dvh.errors[:glasscutting1_color], "El color del vidrio 1 no puede estar en blanco"
    assert_includes dvh.errors[:glasscutting2_type], "El tipo de vidrio 2 no puede estar en blanco"
    assert_includes dvh.errors[:glasscutting2_thickness], "El espesor del vidrio 2 no puede estar en blanco"
    assert_includes dvh.errors[:glasscutting2_color], "El color del vidrio 2 no puede estar en blanco"
    assert_includes dvh.errors[:type_opening], "El tipo de abertura no puede estar en blanco"
    assert_includes dvh.errors[:project].map(&:to_s).join(" ").downcase, "debe existir"
  end

  test "validates numerical values" do
    dvh = Dvh.new(
      height: 0,
      width: 0,
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project
    )
    
    assert_not dvh.valid?
    assert_includes dvh.errors[:height], "El alto debe ser mayor que 0"
    assert_includes dvh.errors[:width], "El ancho debe ser mayor que 0"
  end

  test "validates enum values" do
    dvh = Dvh.new(
      height: 100,
      width: 100,
      typology: "Test",
      innertube: 99,
      glasscutting1_type: "INVALID",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "INVALID",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "INVALID",
      project: @project
    )
    
    assert_not dvh.valid?
    assert_includes dvh.errors[:innertube], "La cámara del vidrio no es válida"
    assert_includes dvh.errors[:glasscutting1_type], "El tipo de vidrio 1 no es válido"
    assert_includes dvh.errors[:glasscutting2_type], "El tipo de vidrio 2 no es válido"
    assert_includes dvh.errors[:type_opening], "El tipo de abertura no es valido"
  end

  test "creates a valid record with all required attributes" do
    dvh = Dvh.new(
      height: 100,
      width: 100,
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project
    )
    
    assert dvh.valid?, dvh.errors.full_messages.join(", ")
  end

  # Pruebas para métodos personalizados
  
  test "calculates price automatically when not provided" do
    # Crear precios de vidrio de prueba
    glass_price = GlassPrice.create!(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      selling_price: 150.0
    )
    
    # Configurar el precio de la cámara directamente
    def AppConfig.calculate_innertube_total_price(innertube, perimeter_m)
      50.0 # Valor fijo para la prueba
    end
    
    dvh = Dvh.create!(
      height: 1000, # 1m
      width: 1000,  # 1m (área = 1m²)
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project
    )
    
    # Verificar que se calculó el precio correctamente
    # Precio esperado: (1m² * (150 + 150)) + 50 = 350
    assert_equal 350.0, dvh.price
    
    # Limpiar el método mockeado
    AppConfig.singleton_class.send(:remove_method, :calculate_innertube_total_price)
  end
  
  test "uses provided price instead of calculating it" do
    dvh = Dvh.create!(
      height: 1000,
      width: 1000,
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project,
      price: 500.0
    )
    
    # Verificar que se usó el precio proporcionado
    assert_equal 500.0, dvh.price
  end
  
  test "handles missing glass prices correctly" do
    # Asegurarse de que no hay precios de vidrio en la base de datos
    GlassPrice.destroy_all
    
    # Configurar el método calculate_innertube_total_price para esta prueba
    def AppConfig.calculate_innertube_total_price(innertube, perimeter_m)
      50.0 # Valor fijo para la prueba
    end
    
    dvh = Dvh.create(
      height: 1000,
      width: 1000,
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project
    )
    
    # Verificar que el precio es 0 cuando no hay precios de vidrio
    assert_equal 50.0, dvh.price  # Solo el precio de la cámara, ya que no hay precios de vidrio
    
    # Limpiar el método mockeado
    AppConfig.singleton_class.send(:remove_method, :calculate_innertube_total_price)
  end
  
  # Prueba de exclusión mutua para los tipos de vidrio
  test "validates that glass types are valid" do
    dvh = Dvh.new(
      height: 100,
      width: 100,
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "INVALID",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project
    )
    
    assert_not dvh.valid?
    assert_includes dvh.errors[:glasscutting1_type], "El tipo de vidrio 1 no es válido"
  end
  
  # Prueba de exclusión mutua para los colores de vidrio
  test "must validate that the glass colors are valid" do
    dvh = Dvh.new(
      height: 100,
      width: 100,
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INVALID",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project
    )
    
    assert_not dvh.valid?
    assert_includes dvh.errors[:glasscutting1_color], "El color del vidrio 1 no es válido"
  end
  
  # Prueba de exclusión mutua para los espesores de vidrio
  test "must validate that the glass thicknesses are valid" do
    dvh = Dvh.new(
      height: 100,
      width: 100,
      typology: "Test",
      innertube: 6,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "INVALID",
      glasscutting1_color: "INC",
      glasscutting2_type: "LAM",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "INC",
      type_opening: "PVC",
      project: @project
    )
    
    assert_not dvh.valid?
    assert_includes dvh.errors[:glasscutting1_thickness], "El grosor del vidrio 1 no es válido"
  end
end