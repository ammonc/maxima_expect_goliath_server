gem "minitest"
require "lib/maxima_expect_runner"

class MaximaExpectRunnerTest < MiniTest::Unit::TestCase
  def setup
    @mc = MaximaExpectRunner.new
  end

  def test_single_command_syntax_ok
    start_line_num_helper

    cmd = "tex(integrate(x,x));"
    run_flow_helper(cmd)
    assert_not_nil @response  
    @mc.interpret_response(@response)

    assert_not_nil @mc.tex_output_line   
    puts "Tex output was:  " + @mc.tex_output_line
    lindex = @mc.tex_output_line.index("$$")   
    rindex = @mc.tex_output_line.rindex("$$")
    assert_not_nil lindex
    assert_not_nil rindex
    assert_not_equal lindex, rindex  # should be a pair of dollar signs on each end
 
    assert_line_num_is_greater_by 1
  end
  
  def test_single_command_missing_semicolon
    cmd = "tex(integrate(x,x))"  # DELIBERATELY MISSING SEMICOLON
    assert_nothing_raised do  # changed to automatically add semicolon
      run_flow_helper(cmd)
    end  
  end
  
  def test_multiple_commands_missing_semicolon_imbetween
    cmd = "simplify(x^3-x^3) tex(integrate(x,x));"  # DELIBERATELY MISSING SEMICOLON
    run_flow_helper(cmd)
    assert_not_nil @response
    assert_raises MaximaSyntaxError do
      @mc.interpret_response(@response)
    end  
  end

  def test_multiple_commands_missing_semicolon_at_the_end
    cmd = "tex(integrate(x,x)); simplify(x^5 - x^5)"  # DELIBERATELY MISSING SEMICOLON
    # Interestingly, this just acts as if the first command was entered (essentially waiting on a terminating character in order to execute the next command)
    assert_nothing_raised { run_flow_helper(cmd) }
  end
  
  def test_multiple_commands_on_one_line_syntax_ok
    start_line_num_helper

    cmd = "diff(tan(u),u);tex(integrate(x^2,x));"
    run_flow_helper(cmd)
    assert_not_nil @response  
    @mc.interpret_response(@response)

    assert_not_nil @mc.tex_output_lines
    assert_equal 1, @mc.tex_output_lines.size
    assert_not_nil @mc.tex_output_line   
    puts "Tex output was:  " + @mc.tex_output_line
    lindex = @mc.tex_output_line.index("$$")   
    rindex = @mc.tex_output_line.rindex("$$")
    assert_not_nil lindex
    assert_not_nil rindex
    assert_not_equal lindex, rindex  # should be a pair of dollar signs on each end
    
    assert_not_nil @mc.output_lines
    assert_equal 2, @mc.output_lines.size
    assert @mc.output_lines.first =~ /^\(%o#{@start_line_num + 1}\)/  
    assert @mc.output_lines.last =~ /^\(%o#{@start_line_num + 2}\)\s+false/  # tex one should return false on the output line

    assert_line_num_is_greater_by 2 
  end

  def test_linenum_command_low_level
    start_line_num_helper

    cmd = "linenum;"
    @mc.send_command(cmd)
    @response = @mc.wait_for_input_prompt
    assert_not_nil @response  
    @mc.interpret_response(@response)
    
    assert_line_num_is_greater_by 1
  end
  
  def test_linenum_command_high_level
    start_line_num_helper

    linenum = @mc.get_linenum  # Make sure returned from method
    assert_not_nil linenum     
    assert_equal linenum, @mc.linenum  # Make sure they're the same so either one can be used
    
    assert_line_num_is_greater_by 1 
  end

  def teardown
    @mc.quit!
    puts
    puts
  end
  
  
 private 
  def run_flow_helper(cmd)  
    @mc.send_command(cmd)
    @response = @mc.wait_for_input_prompt
  end
    
  def start_line_num_helper  
    @start_line_num = MaximaExpectRunner::NUM_CONFIGURE_STEPS
    assert_not_nil @mc.linenum
    assert @mc.linenum.kind_of?(Fixnum)
    assert_equal @start_line_num, @mc.linenum
  end  

  def assert_line_num_is_greater_by(num)
    assert_not_nil @start_line_num
    assert_not_nil @mc.linenum # Make sure instance variable set
    assert @mc.linenum.kind_of?(Fixnum)  # Make sure the return value is already an integer
    assert_equal @start_line_num + num, @mc.linenum
  end
end
