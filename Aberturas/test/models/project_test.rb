require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @project = projects(:one)
  end

  test "should assign typologies to glasscuttings and dvhs on save" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create glasscuttings
    glasscutting1 = project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "4+4",
      color: "INC",
      location: "DINTEL",
      height: 100,
      width: 50,
      price: 100.0
    )
    
    glasscutting2 = project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "3+3",
      color: "GRS",
      location: "JAMBA_I",
      height: 200,
      width: 75,
      price: 200.0
    )

    # Create DVH
    dvh = project.dvhs.create!(
      innertube: 9,
      location: "DINTEL",
      height: 150,
      width: 100,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "4+4",
      glasscutting1_color: "INC",
      glasscutting2_type: "FLO",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "GRS",
      price: 300.0
    )

    # Trigger typology assignment
    project.save!

    # Reload to get fresh data
    glasscutting1.reload
    glasscutting2.reload
    dvh.reload

    # Assert typologies are assigned correctly
    assert_equal "V1", glasscutting1.typology
    assert_equal "V2", glasscutting2.typology
    assert_equal "V3", dvh.typology
  end

  test "should reassign typologies when glasscutting is deleted" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create glasscuttings
    glasscutting1 = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", location: "DINTEL",
      height: 100, width: 50, price: 100.0
    )
    
    glasscutting2 = project.glasscuttings.create!(
      glass_type: "FLO", thickness: "3+3", color: "GRS", location: "JAMBA_I",
      height: 200, width: 75, price: 200.0
    )

    dvh = project.dvhs.create!(
      innertube: 9, location: "DINTEL", height: 150, width: 100,
      glasscutting1_type: "LAM", glasscutting1_thickness: "4+4", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "3+3", glasscutting2_color: "GRS",
      price: 300.0
    )

    project.save!

    # Verify initial typologies
    glasscutting1.reload
    glasscutting2.reload
    dvh.reload
    
    assert_equal "V1", glasscutting1.typology
    assert_equal "V2", glasscutting2.typology
    assert_equal "V3", dvh.typology

    # Delete first glasscutting
    glasscutting1.destroy!

    # Reload remaining items
    glasscutting2.reload
    dvh.reload

    # Assert typologies are reassigned
    assert_equal "V1", glasscutting2.typology
    assert_equal "V2", dvh.typology
  end

  test "should reassign typologies when dvh is deleted" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", location: "DINTEL",
      height: 100, width: 50, price: 100.0
    )

    dvh1 = project.dvhs.create!(
      innertube: 9, location: "DINTEL", height: 150, width: 100,
      glasscutting1_type: "LAM", glasscutting1_thickness: "4+4", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "3+3", glasscutting2_color: "GRS",
      price: 300.0
    )

    dvh2 = project.dvhs.create!(
      innertube: 12, location: "JAMBA_I", height: 200, width: 150,
      glasscutting1_type: "COL", glasscutting1_thickness: "5+5", glasscutting1_color: "BRC",
      glasscutting2_type: "LAM", glasscutting2_thickness: "4+4", glasscutting2_color: "STB",
      price: 400.0
    )

    project.save!

    # Verify initial typologies
    glasscutting.reload
    dvh1.reload
    dvh2.reload
    
    assert_equal "V1", glasscutting.typology
    assert_equal "V2", dvh1.typology
    assert_equal "V3", dvh2.typology

    # Delete first DVH
    dvh1.destroy!

    # Reload remaining items
    glasscutting.reload
    dvh2.reload

    # Assert typologies are reassigned
    assert_equal "V1", glasscutting.typology
    assert_equal "V2", dvh2.typology
  end
end
