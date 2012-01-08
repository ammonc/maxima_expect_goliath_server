require "test/test_helper"

class MaximaMatchProcessorTest < MiniTest::Unit::TestCase
  def test_single_result_match
    s = "$$s^2/n$$\n(%o3) false\n(%i4)"
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 1,  mmp.results.keys.size
    puts mmp.results.inspect
  end

  def test_multiple_result_match_from_multiple_commands_on_one_line_std_then_tex

#This was sent and this was the response:
# Sending command 'diff(tan(u),u);tex(integrate(x^2,x));'
# ...
# ["\n(%o3) sec(u)^2\n$${{x^3}\\over{3}}$$\n(%o4) false\n(%i5) "]
#"(%o3) sec(u)^2\n$${{x^3}\\over{3}}$$\n(%o4) false\n(%i5)"
#"5"

    s = "\n(%o3) sec(u)^2\n$${{x^3}\\over{3}}$$\n(%o4) false\n(%i5) "
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 2, mmp.results.keys.size
    puts mmp.results.inspect
    # test individual results from the above...
    assert_equal [3,4], mmp.results.keys.sort
    assert_equal 'sec(u)^2', mmp.results[3]
    assert_equal '$${{x^3}\\over{3}}$$', mmp.results[4]
  end
  

  def test_multiple_result_match_from_multiple_commands_on_one_line_tex_then_std
    s = "\n$${{x^3}\\over{3}}$$\n(%o3) false\n(%o4) sec(u)^2\n(%i5) "
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 2, mmp.results.keys.size
    puts mmp.results.inspect
    # test individual results from the above...
    assert_equal [3,4], mmp.results.keys.sort
    assert_equal '$${{x^3}\\over{3}}$$', mmp.results[3]
    assert_equal 'sec(u)^2', mmp.results[4]
  end


  def test_multiple_result_match
    next_input_number = 6
    s = "$$s^2/n$$\n(%o3) false\n(%i4)\n$$s^2/n$$\n(%o4) false\n(%i5)\n$$s^2/n$$\n(%o5) false\n(%i6)"
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 3, mmp.results.keys.size
    puts mmp.results.inspect
    # test individual results from the above...
    assert_equal [3,4,5], mmp.results.keys.sort
    for key in mmp.results.keys do
      assert_equal '$$s^2/n$$', mmp.results[key]
    end
  end

  # contrived, false example - make sure we raise an exception
  def test_multiple_result_match_with_same_input_numbers_raises_clobber
    assert_raises Maxima::ResultClobberException do
      next_input_number = 4
      s = "$$s^2/n$$\n(%o3) false\n(%i4)\n$$s^2/n$$\n(%o4) false\n(%i5)\n$$s^2/n$$\n(%o3) false\n(%i6)"
      mmp = Maxima::MatchProcessor.new([s])
    end
  end
  
  def test_empty_string_raises_no_iteration
    assert_raises Maxima::NoIterationException do
      s = ""
      mmp = Maxima::MatchProcessor.new([s])
    end
  end
  
  def test_whitespace_removed
    next_input_number = 3456
    s = "\n\t   (%o#{next_input_number-1})\t\r\t\n(%i#{next_input_number})"
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 1, mmp.results.keys.size
    assert mmp.results[next_input_number - 1].empty?
  end

  def test_tex_integrate_x
    next_input_number = 4
    s = "$${{x^2}\\over{2}}$$\n(%o3) false\n(%i4) " 
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 1, mmp.results.keys.size
    assert_equal '$${{x^2}\over{2}}$$', mmp.results[next_input_number - 1]
  end

#(%i3) diff(tan(x),x);
#
#(%o3) sec(x)^2
#(%i4)
  def test_diff_tan_x
    next_input_number = 4
    s = "\n(%o3) sec(x)^2\n(%i4) " 
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 1, mmp.results.keys.size
    assert_equal 'sec(x)^2', mmp.results[next_input_number - 1]
  end

  def test_syntax_error_followed_by_tex_simple
    # from example of sending two commands where missing a semicolon between them:
    # Sending command 'simplify(x^3-x^3) tex(integrate(x,x));'
    s = "incorrect syntax: TEX is not an infix operator\nmplify(x^3-x^3)Spacetex(\n                  ^\n(%i3) "
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 4, mmp.results.keys.size
    assert_equal 'sec(x)^2', mmp.results[]
  end
  
  def test_syntax_error_followed_by_tex_complex
    # from example of sending two commands where missing a semicolon between them:
    # Sending command 'simplify(x^3-x^3) 1;tex(integrate(x,x));'
    skip
    # TODO:  string below is incorrect...
    s = "incorrect syntax: TEX is not an infix operator\nmplify(x^3-x^3)Spacetex(\n                  ^\n(%i3) "
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 4, mmp.results.keys.size
    assert_equal 'sec(x)^2', mmp.results[]
  end

  def test_syntax_error_followed_by_std_complex
    # from example of sending two commands where missing a semicolon between them:
    # Sending command 'simplify(x^3-x^3) 1;integrate(x,x);'
    # TODO:  string below is incorrect...
    mmp = Maxima::MatchProcessor.new([s])
    assert_equal 4, mmp.results.keys.size
    assert_equal 'sec(x)^2', mmp.results[]
  end

=begin
(%i8) tex(sin(x)/x);diff(integrate(x,x),x);
$${{\sin x}\over{x}}$$
(%o8) false
(%o9) x
(%i10) z - y; x;

(%o10) z-y
(%o11) x
=end

end
