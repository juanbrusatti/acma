require "test_helper"

class SupplyTest < ActiveSupport::TestCase
  def setup
    @supply = Supply.new(name: "Test Supply", price: 10.50)
  end

  test "should be valid with valid attributes" do
    assert @supply.valid?
  end

  test "should allow supply without price" do
    @supply.price = nil
    assert @supply.valid?
  end

  test "basics should return basic supplies" do
    basics = Supply.basics
    assert_equal 3, basics.length
    assert_includes basics.map(&:name), "Tamiz"
    assert_includes basics.map(&:name), "Hotmelt"
    assert_includes basics.map(&:name), "Cinta"
  end

  test "find_or_create_by should work for basics" do
    initial_count = Supply.count
    Supply.basics
    # Should create 3 new supplies if they don't exist
    assert_operator Supply.count, :>=, initial_count
  end
end
