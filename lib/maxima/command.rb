
module Maxima

  class EmptyCommandException < ArgumentError
  end

=begin
  class MultipleCommandException < ArgumentError
  end
=end

  class Command < String

    def initialize(cmdin)
      super(cmdin)
      # chomp just takes off \n or \r\n
      # strip takes off whitespace on either side
      chomp!
      strip!
      raise EmptyCommandException if empty?
      self << ';' unless ends_with_semicolon_or_dollar_sign?
=begin
      raise MultipleCommandException if (index(';') && index('$')) || (index(';') != rindex(';')) || (index('$') != rindex('$'))
=end
    end

    def last_char
      self[-1]
    end

      # $ suppresses outputting the result but returns with the next input prompt

  #(%i1) integrate(x,x)$
  #
  #(%i2)
    def ends_with_semicolon_or_dollar_sign?
      proper_termination_char = [';', '$'].any? { |s| last_char == s }
    end

    # make sure that commands are hacker safe
    def sanitize_maxima_command_for_security(command)
      raise "NotImplementedException"
    end
    
    # TODO:  needs to be improved to 
    #   1. detect if command already has tex() surrounding it
    #   2. handle multiple commands on the same line with ; imbetween 
    #     a. more difficult
    def to_tex
      return_str = nil
      if self =~ /tex\(/
	return_str = self 
      else
	cmd_wo_last_char, last_char = split_string_and_last_char 
	return_str = "tex(#{cmd_wo_last_char})#{last_char}"
      end
      return Command.new(return_str)
    end

   private
   
    def split_string_and_last_char
      return self[0..-2], last_char # separate last character and send it separately 
    end  
  end

end
