require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @project = projects(:one)
    
    # Setup pricing data for tests using fixtures for supplies
    # Fixtures already provide: Tamiz, Hotmelt, Cinta, etc.
    
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)
    GlassPrice.create!(glass_type: "FLO", thickness: "4+4", color: "GRS", selling_price: 150.0)
  end

  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "should get new" do
    get new_project_url
    assert_response :success
  end

  test "should create project with frontend calculated prices" do
    assert_difference('Project.count') do
      post projects_url, params: {
        project: {
          name: "Test Project",
          phone: "123456789",
          description: "Test description",
          status: "Pendiente",
          address: "Test Address",
          price: 1210.0,           # Frontend calculated total
          price_without_iva: 1000.0, # Frontend calculated subtotal
          glasscuttings_attributes: {
            "0" => {
              glass_type: "LAM",
              thickness: "3+3",
              color: "INC",
              location: "DINTEL",
              height: 1000,
              width: 800,
              price: 400.0 # Frontend calculated price
            }
          },
          dvhs_attributes: {
            "0" => {
              innertube: "6",
              location: "DINTEL",
              height: 1000,
              width: 800,
              glasscutting1_type: "LAM",
              glasscutting1_thickness: "3+3",
              glasscutting1_color: "INC",
              glasscutting2_type: "FLO",
              glasscutting2_thickness: "4+4",
              glasscutting2_color: "GRS",
              price: 600.0 # Frontend calculated price
            }
          }
        }
      }
    end

    project = Project.last
    assert_equal 1000.0, project.price_without_iva
    assert_equal 1210.0, project.price
    
    glasscutting = project.glasscuttings.first
    assert_equal 400.0, glasscutting.price
    
    dvh = project.dvhs.first
    assert_equal 600.0, dvh.price

    assert_redirected_to projects_path
  end

  test "should create project without frontend prices and trigger backend calculation" do
    assert_difference('Project.count') do
      post projects_url, params: {
        project: {
          name: "Test Project Backend",
          phone: "123456789",
          description: "Test description",
          status: "Pendiente",
          address: "Test Address",
          # No price or price_without_iva provided
          glasscuttings_attributes: {
            "0" => {
              glass_type: "LAM",
              thickness: "3+3",
              color: "INC",
              location: "DINTEL",
              height: 1000,
              width: 800
              # No price provided - should trigger backend calculation
            }
          },
          dvhs_attributes: {
            "0" => {
              innertube: "6",
              location: "DINTEL",
              height: 1000,
              width: 800,
              glasscutting1_type: "LAM",
              glasscutting1_thickness: "3+3",
              glasscutting1_color: "INC",
              glasscutting2_type: "FLO",
              glasscutting2_thickness: "4+4",
              glasscutting2_color: "GRS"
              # No price provided - should trigger backend calculation
            }
          }
        }
      }
    end

    project = Project.last
    
    glasscutting = project.glasscuttings.first
    assert glasscutting.price.present?, "Glasscutting should have calculated price"
    assert glasscutting.price > 0, "Glasscutting price should be greater than 0"
    
    dvh = project.dvhs.first
    assert dvh.price.present?, "DVH should have calculated price"
    assert dvh.price > 0, "DVH price should be greater than 0"

    assert_redirected_to projects_path
  end

  test "should create project with mixed frontend and backend pricing" do
    assert_difference('Project.count') do
      post projects_url, params: {
        project: {
          name: "Test Mixed Pricing",
          phone: "123456789",
          description: "Test description",
          status: "Pendiente",
          address: "Test Address",
          glasscuttings_attributes: {
            "0" => {
              glass_type: "LAM",
              thickness: "3+3",
              color: "INC",
              location: "DINTEL",
              height: 1000,
              width: 800,
              price: 333.33 # Frontend calculated
            }
          },
          dvhs_attributes: {
            "0" => {
              innertube: "6",
              location: "DINTEL",
              height: 1000,
              width: 800,
              glasscutting1_type: "LAM",
              glasscutting1_thickness: "3+3",
              glasscutting1_color: "INC",
              glasscutting2_type: "FLO",
              glasscutting2_thickness: "4+4",
              glasscutting2_color: "GRS"
              # No price - should trigger backend calculation
            }
          }
        }
      }
    end

    project = Project.last
    
    glasscutting = project.glasscuttings.first
    assert_equal 333.33, glasscutting.price, "Should use frontend calculated price"
    
    dvh = project.dvhs.first
    assert dvh.price.present?, "DVH should have backend calculated price"
    assert dvh.price > 0, "DVH price should be greater than 0"

    assert_redirected_to projects_path
  end

  test "should show project" do
    get project_url(@project)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_url(@project)
    assert_response :success
  end

  test "should update project with new pricing" do
    # Create a valid project for this test
    project = Project.create!(
      name: "Test Project for Update",
      phone: "123456789",
      status: "Pendiente"
    )
    
    new_price_without_iva = 1239.67
    
    patch project_url(project), params: {
      project: {
        name: project.name,
        phone: project.phone,
        price_without_iva: new_price_without_iva
      }
    }
    
    project.reload
    assert_equal new_price_without_iva, project.price_without_iva
    
    assert_redirected_to projects_path
  end

  test "should update project via JSON with pricing data" do
    new_price_without_iva = 1487.60
    
    patch project_url(@project), params: {
      project: {
        name: @project.name,
        phone: "123456789", # Ensure phone is provided
        status: "En Proceso",
        price_without_iva: new_price_without_iva
      }
    }, as: :json
    
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert response_data["project"]
    assert response_data["status_badge_html"]
    
    @project.reload
    assert_equal new_price_without_iva, @project.price_without_iva
    assert_equal "En Proceso", @project.status
  end

  test "should destroy project" do
    assert_difference('Project.count', -1) do
      delete project_url(@project)
    end

    assert_redirected_to projects_path
  end

  test "create should handle validation errors gracefully" do
    assert_no_difference('Project.count') do
      post projects_url, params: {
        project: {
          # Missing required name and phone
          description: "Test description",
          status: "Pendiente"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "update should handle validation errors gracefully" do
    patch project_url(@project), params: {
      project: {
        name: "", # Invalid empty name
        phone: ""  # Invalid empty phone
      }
    }

    assert_response :unprocessable_entity
    
    @project.reload
    assert_not_equal "", @project.name # Should not be updated
  end

  test "create accepts nested attributes with proper indices" do
    assert_difference('Project.count') do
      assert_difference('Glasscutting.count', 2) do
        assert_difference('Dvh.count', 1) do
          post projects_url, params: {
            project: {
              name: "Multi Component Project",
              phone: "123456789",
              description: "Test description",
              status: "Pendiente",
              address: "Test Address",
              glasscuttings_attributes: {
                "0" => {
                  glass_type: "LAM",
                  thickness: "3+3",
                  color: "INC",
                  location: "DINTEL",
                  height: 1000,
                  width: 800,
                  price: 200.0
                },
                "1" => {
                  glass_type: "FLO",
                  thickness: "4+4",
                  color: "GRS",
                  location: "JAMBA_I",
                  height: 1200,
                  width: 600,
                  price: 180.0
                }
              },
              dvhs_attributes: {
                "0" => {
                  innertube: "9",
                  location: "DINTEL",
                  height: 1500,
                  width: 1000,
                  glasscutting1_type: "LAM",
                  glasscutting1_thickness: "3+3",
                  glasscutting1_color: "INC",
                  glasscutting2_type: "FLO",
                  glasscutting2_thickness: "4+4",
                  glasscutting2_color: "GRS",
                  price: 450.0
                }
              }
            }
          }
        end
      end
    end

    project = Project.last
    assert_equal 2, project.glasscuttings.count
    assert_equal 1, project.dvhs.count
    
    # Check that prices were properly assigned
    glasscuttings = project.glasscuttings.order(:id)
    assert_equal 200.0, glasscuttings.first.price
    assert_equal 180.0, glasscuttings.second.price
    
    dvh = project.dvhs.first
    assert_equal 450.0, dvh.price

    assert_redirected_to projects_path
  end
end
