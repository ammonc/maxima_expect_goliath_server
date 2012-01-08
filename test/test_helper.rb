$:.unshift(File.dirname(__FILE__) + '/../lib')

require "maxima"

require "test/.minitest"
require "redgreen"

#=== Benchmarks
#
#Add benchmarks to your regular unit tests. If the unit tests fail, the
#benchmarks won't run.
#
# optionally run benchmarks, good for CI-only work!
require 'minitest/benchmark' if ENV['BENCH']
