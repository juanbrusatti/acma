require 'test_helper'

# Test para Glassplate
class GlassplateTest < ActiveSupport::TestCase
  test "debe tener atributos requeridos" do
    glassplate = Glassplate.new
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:glass_type], "El tipo de vidrio no puede estar en blanco"
    assert_includes glassplate.errors[:thickness], "El espesor no puede estar en blanco"
    assert_includes glassplate.errors[:color], "El color no puede estar en blanco"
    assert_includes glassplate.errors[:width], "El ancho no puede estar en blanco"
    assert_includes glassplate.errors[:height], "El alto no puede estar en blanco"
    assert_includes glassplate.errors[:quantity], "La cantidad no puede estar en blanco"
  end

  # Test para validar valores de enumeraciones
  test "debe validar valores de enumeraciones" do
    glassplate = Glassplate.new(
      glass_type: "INVALID",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:glass_type], "El tipo de vidrio debe ser uno de: LAM, FLO, COL"
  end

  # Test para crear un registro válido
  test "debe crear un registro válido" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert glassplate.valid?
  end

  # Pruebas para el método full_description
  test "debe devolver la descripción completa del vidrio" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_equal "LAM 3+3 - INC", glassplate.full_description
  end

  # Pruebas de valores límite para width y height
  test "debe validar que el ancho sea mayor que 0" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 0,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:width], "El ancho debe ser mayor que 0"
  end

  test "debe validar que el alto sea mayor que 0" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 0,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:height], "El alto debe ser mayor que 0"
  end

  test "debe validar que la cantidad sea mayor o igual a 0" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: -1
    )
    
    assert_not glassplate.valid?
    assert_not_empty glassplate.errors[:quantity], "Debería haber un error de validación para cantidad"
  end

  # Pruebas de inclusión para glass_type
  test "debe validar que el tipo de vidrio sea LAM, FLO o COL" do
    glassplate = Glassplate.new(
      glass_type: "INVALID",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:glass_type], "El tipo de vidrio debe ser uno de: LAM, FLO, COL"
  end

  # Pruebas de inclusión para thickness
  test "debe validar que el espesor sea válido" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "2+2",  # Inválido
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:thickness], "El espesor debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  end

  # Pruebas de inclusión para color
  test "debe validar que el color sea válido" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INVALID",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:color], "El color debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  end

  # Prueba de borde: valores mínimos válidos
  test "debe ser válido con valores mínimos" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 0.1,  # Valor mínimo mayor que 0
      height: 0.1, # Valor mínimo mayor que 0
      quantity: 0   # Valor mínimo permitido
    )
    
    assert glassplate.valid?
  end
end