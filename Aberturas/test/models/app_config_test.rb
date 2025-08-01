require "test_helper"

class AppConfigTest < ActiveSupport::TestCase
  def setup
    AppConfig.delete_all # Clean up any existing configs
  end

  test "validates presence of key and value" do
    config = AppConfig.new
    assert_not config.valid?
    assert_includes config.errors[:key], "no puede estar en blanco"
    assert_includes config.errors[:value], "no puede estar en blanco"
  end

  test "validates uniqueness of key" do
    AppConfig.create!(key: "test_key", value: "test_value")
    duplicate = AppConfig.new(key: "test_key", value: "another_value")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "ya ha sido tomado"
  end

  test "current_mep_rate returns 0.0 when no MEP rate is set" do
    assert_equal 0.0, AppConfig.current_mep_rate
  end

  test "current_mep_rate returns the stored MEP rate" do
    AppConfig.create!(key: "mep_rate", value: "1250.75")
    assert_equal 1250.75, AppConfig.current_mep_rate
  end

  test "set_mep_rate creates new config when none exists" do
    AppConfig.delete_all
    
    AppConfig.set_mep_rate(1200.50)
    
    config = AppConfig.find_by(key: "mep_rate")
    assert_not_nil config
    assert_equal "1200.5", config.value
  end

  test "set_mep_rate updates existing config" do
    AppConfig.create!(key: "mep_rate", value: "1000.0")
    
    rate = AppConfig.set_mep_rate(1500.25)
    
    assert_equal 1500.25, rate
    assert_equal 1500.25, AppConfig.current_mep_rate
    assert_equal 1, AppConfig.where(key: "mep_rate").count
  end

  test "mep_rate_set? returns false when no MEP rate exists" do
    assert_not AppConfig.mep_rate_set?
  end

  test "mep_rate_set? returns true when MEP rate exists" do
    AppConfig.create!(key: "mep_rate", value: "1200.0")
    assert AppConfig.mep_rate_set?
  end

  test "mep_rate_set? returns false when MEP rate is 0" do
    AppConfig.create!(key: "mep_rate", value: "0")
    assert_not AppConfig.mep_rate_set?
  end
end
