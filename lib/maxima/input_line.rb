module Maxima
  class InputLine
    
    attr_accessor :cmds

    def initialize(cmdin = nil)
      if cmdin
	if cmdin.instance_of?(Array)
	  # assume an array of strings
	  @cmds = cmdin.collect { |s| Command.new(s) } 
	elsif cmdin.instance_of?(Command)
	  @cmds = [cmdin]
	elsif cmdin.instance_of?(String)
	  # TODO:  support a multi-command string initialization here...
	  a = cmdin.split(/[\$;]/)
          # split is going to turn '1$' into ['1']
          # then Maxima::Command gracefully adds the semicolon
          # in order to avoid losing the termination character (if it is a termination character), we append it to the last array element...
          a.last << cmdin[-1] if ['$',';'].member?(cmdin[-1])
	  @cmds = a.collect { |s| Command.new(s) }
	end
      else
	@cmds = []
      end
    end

    def push(new_element)
      @cmds << new_element 
    end
    
    def <<(new_element)
      push(new_element)
    end


    alias :add :push

  end
end

