require "test/test_helper"
 
class MaximaCommandTest < MiniTest::Unit::TestCase
  def test_empty_string_raises_empty_command_exception
    assert_raises Maxima::EmptyCommandException do
      s = ""
      mc = Maxima::Command.new(s)
    end
  end
  
  def test_trailing_dollar_sign_not_converted_to_semicolon
    s = "1$"
    mc = Maxima::Command.new(s)
    assert_equal s, mc
  end
  
  
  def test_left_whitespace_removed
    s = "\n\t   1;"
    mc = Maxima::Command.new(s)
    assert_equal "1;", mc
  end
  
  def test_right_whitespace_removed
    s = "1;\t\r\t\n "
    mc = Maxima::Command.new(s)
    assert_equal "1;", mc
  end
  
  def test_both_whitespace_removed
    s = "\n\t   1;\t\r\t\n "
    mc = Maxima::Command.new(s)
    assert_equal "1;", mc
  end
  
  def test_both_whitespace_removed_and_semicolon_added
    s = "\n\t   1\t\r\t\n "
    mc = Maxima::Command.new(s)
    assert_equal "1;", mc
  end
  
  def test_multiple_commands_allowed
    s = "1;2$"
    mc = Maxima::Command.new(s)
    assert_equal s, mc
  end
  
  def test_multiple_commands_with_implied_ending_semicolon_has_semicolon_added
    s = "1;2"
    mc = Maxima::Command.new(s)
    assert_equal s + ';', mc
  end
  
  def test_call_convert_to_tex_on_a_command_already_requesting_tex_output
    s = "tex(integrate(x/2,x));"
    mc = Maxima::Command.new(s)
    t = mc.to_tex
    assert_equal s, t
    assert_kind_of Maxima::Command, t # not a String
  end
  
  def test_call_convert_to_tex_on_a_command_not_already_requesting_tex_output
    s = "integrate(x/2,x);"
    mc = Maxima::Command.new(s)
    t = mc.to_tex
    assert_equal "tex(integrate(x/2,x));", t
    assert_kind_of Maxima::Command, t # not a String
  end
end
