require 'test_helper'

class ScrapTest < ActiveSupport::TestCase
  test "debe tener atributos requeridos" do
    scrap = Scrap.new
    assert_not scrap.valid?
    assert_includes scrap.errors[:ref_number], "El número de referencia no puede estar en blanco"
    assert_includes scrap.errors[:output_work], "La obra de salida no puede estar en blanco"
    assert_includes scrap.errors[:scrap_type], "El tipo de vidrio no puede estar en blanco"
    assert_includes scrap.errors[:thickness], "El grosor del retazo no puede estar en blanco"
    assert_includes scrap.errors[:color], "El color no puede estar en blanco"
    assert_includes scrap.errors[:width], "El ancho del retazo no puede estar en blanco"
    assert_includes scrap.errors[:height], "El alto del retazo no puede estar en blanco"  # Actualizado
  end

  test "debe validar valores de enumeraciones" do
    scrap = Scrap.new(
      ref_number: "TEST001",
      output_work: "OBRA TEST",
      scrap_type: "INVALID",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      status: "Disponible"
    )
    
    assert_not scrap.valid?
    assert_includes scrap.errors[:scrap_type], "El tipo debe ser uno de: LAM, FLO, COL"
  end

  test "debe crear un registro válido" do
    scrap = Scrap.new(
      ref_number: "TEST001",
      output_work: "OBRA TEST",
      scrap_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      status: "Disponible"
    )
    
    assert scrap.valid?, scrap.errors.full_messages.join(", ")
  end
end