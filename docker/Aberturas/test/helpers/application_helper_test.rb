require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "human_glass_type should return correct human-readable type" do
    assert_equal 'Laminado', human_glass_type('LAM')
    assert_equal 'Float', human_glass_type('FLO')
    assert_equal 'Cool Lite', human_glass_type('COL')
    assert_equal 'INVALID', human_glass_type('INVALID')
  end

  test "human_glass_type should be case insensitive" do
    assert_equal 'Laminado', human_glass_type('lam')
    assert_equal 'Float', human_glass_type('Flo')
  end

  test "human_glass_color should return correct human-readable color" do
    assert_equal 'Incoloro', human_glass_color('INC')
    assert_equal 'Gris', human_glass_color('GRIS')
    assert_equal 'Bronce', human_glass_color('BRONCE')
    assert_equal 'Esmerilado', human_glass_color('ESMERILADO')
    assert_equal 'INVALID', human_glass_color('INVALID')
  end

  test "human_glass_color should be case insensitive" do
    assert_equal 'Incoloro', human_glass_color('inc')
    assert_equal 'Gris', human_glass_color('Gris')
  end
end
