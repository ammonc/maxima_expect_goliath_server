#=== Benchmarks
#
#Add benchmarks to your regular unit tests. If the unit tests fail, the
#benchmarks won't run.
#
#  # optionally run benchmarks, good for CI-only work!
#  require 'minitest/benchmark' if ENV["BENCH"]
#
#  class TestMeme < MiniTest::Unit::TestCase
#    # Override self.bench_range or default range is [1, 10, 100, 1_000, 10_000]
#    def bench_my_algorithm
#      assert_performance_linear 0.9999 do |n| # n is a range value
#        @obj.my_algorithm(n)
#      end
#    end
#  end

require 'minitest/autorun'

class TestEMExpect < MiniTest::Unit::TestCase
  def setup
  end

  def test_towrite
    fail
  end
end
