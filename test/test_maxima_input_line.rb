require "test/test_helper"

class MaximaInputLineTest < MiniTest::Unit::TestCase
  def test_multiple_commands_allowed
    s = "1;2$"
    mil = Maxima::InputLine.new(s)
    assert_equal 2, mil.cmds.size
    assert_equal "1;", mil.cmds[0]
    assert_equal "2$", mil.cmds[1]
  end
  
  def test_single_command_works
    s = "1;"
    mil = Maxima::InputLine.new(s)
    assert_equal 1, mil.cmds.size
    assert_equal "1;", mil.cmds[0]
  end
  
  def test_single_command_ending_with_dollar_sign_works
    s = "1$"
    mil = Maxima::InputLine.new(s)
    assert_equal 1, mil.cmds.size
    assert_equal "1$", mil.cmds[0]
  end
  
end
