require "test/test_helper"

class MaximaExpectRunnerTest < MiniTest::Unit::TestCase
  def setup
    @mer = Maxima::ExpectRunner.new
  end

  alias :assert_not_nil :assert
  alias :assert_not_equal :refute_equal

  def test_single_command_syntax_ok
    cmd = "tex(integrate(x,x));"
    run_flow_helper(cmd)
    
    assert_equal 1, @mmp.results.keys.size

    result = '$${{x^2}\over{2}}$$'
    assert_equal result, @mmp.results[1+Maxima::ExpectRunner::NUMBER_SETUP_STEPS]
  end
  
  def test_single_command_missing_semicolon
    cmd = "tex(integrate(x,x))"  # DELIBERATELY MISSING SEMICOLON
    run_flow_helper(cmd)
    
    assert_equal 1, @mmp.results.keys.size

    result = '$${{x^2}\over{2}}$$'
    assert_equal result, @mmp.results[1+Maxima::ExpectRunner::NUMBER_SETUP_STEPS]
  end
  
  def test_multiple_commands_missing_semicolon_imbetween
    cmd = "simplify(x^3-x^3) tex(integrate(x,x));"  # DELIBERATELY MISSING SEMICOLON
    assert_raises Maxima::SyntaxError do
      run_flow_helper(cmd)
    end  
  end

  def test_multiple_commands_missing_semicolon_at_the_end
    cmd = "tex(integrate(x,x)); simplify(x^5 - x^5)"  # DELIBERATELY MISSING SEMICOLON

# maxima just hangs on to the previous input waiting for a semicolon...
# Should we enforce that it ends with a ; ?
# We just add the missing semicolon, assuming that the user intended it 

#(%i3) tex(integrate(x,x)); simplify(x^5 - x^5)
#$${{x^2}\over{2}}$$
#(%o3)                                false
#(%i4) ;
#(%o4)                             simplify(0)
#(%i5) simplify(x^5 - x^5);
#(%o5)                             simplify(0)


    # Interestingly, this just acts as if the first command was entered (essentially waiting on a terminating character in order to execute the next command)
    run_flow_helper(cmd)

    assert_equal 2, @mmp.results.keys.size

    result = '$${{x^2}\over{2}}$$'
    assert_equal result, @mmp.results[1+Maxima::ExpectRunner::NUMBER_SETUP_STEPS]

    result = 'simplify(0)'
    assert_equal result, @mmp.results[2+Maxima::ExpectRunner::NUMBER_SETUP_STEPS]
  end
  
  def test_multiple_commands_on_one_line_syntax_ok_is_allowed
    cmd = "diff(tan(u),u);tex(integrate(x^2,x));"

# after display2d:false;
#(%i7) diff(tan(u),u);tex(integrate(x^2,x));
#
#(%o7) sec(u)^2
#$${{x^3}\over{3}}$$
#(%o8) false

    run_flow_helper(cmd)

    assert_equal 2, @mmp.results.keys.size

    result = 'sec(u)^2'
    assert_equal result, @mmp.results[1+Maxima::ExpectRunner::NUMBER_SETUP_STEPS]

    result = '$${{x^3}\over{3}}$$'
    assert_equal result, @mmp.results[2+Maxima::ExpectRunner::NUMBER_SETUP_STEPS]
  end
 
  # for data collection
  def test_syntax_error_followed_by_tex_simple
    cmd = "simplify(x^3-x^3) tex(integrate(x,x));"
    assert_raises Maxima::SyntaxError do
      raise Maxima::SyntaxError
      #run_flow_helper(cmd)
    end
  end
 
  # It doesn't matter what is after the syntax error.  It doesn't get run.
  def test_syntax_error_followed_by_tex_complex
    cmd = "simplify(x^3-x^3) 1;tex(integrate(x,x));"

    assert_raises Maxima::SyntaxError do
      run_flow_helper(cmd)
    end
  end

  def test_syntax_error_followed_by_std_complex_
    cmd = "simplify(x^3-x^3) 1;integrate(x,x);"

    assert_raises Maxima::SyntaxError do
      run_flow_helper(cmd)
    end
  end
  
  def test_expect_timeout
    cmd = "tex(x/y); simplify(0) tex(sin(x));"

    assert_raises Maxima::TimeoutException do
      run_flow_helper(cmd)
    end
  end

  def teardown
    @mer.quit!
    puts
    puts
  end
  
  
 private 
  def run_flow_helper(cmd)  
    @mc = Maxima::Command.new(cmd) 
    @mer.send_command(@mc)
    @response = @mer.wait_for_input_prompt
    assert_not_nil @response
    @mmp = @mer.interpret_response(@response)
  end

end
