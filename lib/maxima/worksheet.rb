module Maxima
  class Worksheet
    
    attr_accessor :lines

    def initialize(cmdin = nil)
      if cmdin
	if cmdin.instance_of?(Array)
	  # assume an array of strings
	  @cmds = cmdin.collect { |s| InputLine.new(s) } 
	elsif cmdin.instance_of?(InputLine)
	  @lines = [cmdin]
	elsif cmdin.instance_of?(Command)
	  @lines = [InputLine.new(cmdin)]
	elsif cmdin.instance_of?(String)
	  a = cmdin.split(/\n/)
	  @lines = a.collect { |s| InputLine.new(s) }
	end
      else
	@lines = []
      end
    end

    def push(new_element)
      @lines << new_element 
    end
    
    def <<(new_element)
      push(new_element)
    end


    alias :add :push

  end
end

