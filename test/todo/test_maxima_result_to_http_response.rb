require "test/unit"
require "result_calculator"

class TestResultCalculator < Test::Unit::TestCase
  def test_calculate
    maxima_input = "integrate(x^2,x)"
    result = nil 
    assert_nothing_raised { 
      result = ResultCalculator.new(:input => maxima_input) 
    }
  end
end
