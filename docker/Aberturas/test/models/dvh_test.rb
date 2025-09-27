require 'test_helper'

class DvhTest < ActiveSupport::TestCase
  setup do
    # Usando fixtures en lugar de crear directamente
    @project = projects(:one) # Asegúrate de tener un fixture para Project
  end

  test "debe tener atributos requeridos" do
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

  test "debe validar valores numéricos" do
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

  test "debe validar valores de enumeraciones" do
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

  test "debe crear un registro válido" do
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
end