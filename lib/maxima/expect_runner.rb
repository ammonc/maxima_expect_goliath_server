require "expect"

module Maxima
  class TimeoutException < Exception
  end


  class SyntaxError < Exception
  end

  class ExpectRunner
    LAST_INPUT_PROMPT_REGEX = /.*^\(%i\d+\)\s+/m
    # I couldn't get this to work...
    #MULTIPLE_INPUT_PROMPT_REGEX = /{.*?\(%i\d+\)\s+}+/m
    INPUT_PROMPT_REGEX = LAST_INPUT_PROMPT_REGEX 

    NUMBER_SETUP_STEPS = 2  # 2d or not and linesize

    # 1E-3 and 1.0/32/32 didn't work; 1.0/32 does work
    EXPECT_TIMEOUT = 1.0/32 # could raise as high as 4 or 6 maybe, but not much higher than that
    #EXPECT_TIMEOUT = 1 # could raise as high as 4 or 6 maybe, but not much higher than that
    
    ErrorStringsAndExceptions = { /incorrect syntax/i =>  SyntaxError }

    def debug
      false
    end

    def initialize
      start
      wait_for_input_prompt
      # instead of ASCII art style results, insist on one dimensional (as opposed to two-dimensional) results
      configure_1D
    end
    
    def expect(regex_or_s)
      puts "Here's the output from expect..." if debug
      result = @m.expect(regex_or_s, EXPECT_TIMEOUT)
      puts result.inspect #if debug
      result
    end

    def send_command(cmd)
      puts "Sending command '#{cmd}'" #if debug
      # TODO:  could this hang somehow? 
      @m.puts cmd   
      puts "Sent command" if debug
    end
    

    def wait_for_input_prompt
      puts "Waiting for input prompt..." if debug
      response = expect(INPUT_PROMPT_REGEX)
      raise TimeoutException if response.nil?
      puts "Got input prompt" if debug
      response
    end

    def interpret_response(response)
      mmp = MatchProcessor.new(response)
    end
    

    def quit!
      send_command("quit();")

      # From documentation:  The flags argument may be a logical or of the flag values Process::WNOHANG (do not block if no child available) or Process::WUNTRACED (return stopped children that haven't been reported)
      start_time = Time.now
      Process.waitpid(@m.pid, Process::WNOHANG || Process::WUNTRACED)
      stat = $?
      #puts "Child process exited?: #{stat.exited?}" 
      #puts "Child process success?: #{stat.success?}" 
      end_time = Time.now

      elapsed_time = end_time - start_time
      puts "Waited #{elapsed_time.to_f} s  for maxima child process to exit"

      # Not sure if kill necessary
      #puts "Still running before close? #{running?.inspect}"
      @m.close
      #puts "Still running after close? #{running?.inspect}"
    end
    
    # not used or needed - closing the pipe essentially does the trick (at least if the 'quit();' command worked)
    def kill!
      Process.kill(9, @m.pid)  # 9 is a for sure kill
      #If the stream has already been closed, an IOError: closed stream will be raised
    end


   private 
    def start
      puts "About to open pipe and run program..." if debug
      @m = IO.popen("maxima -q", "r+")  # r+ means read-write  O_RDWR is also an option
      puts "Opened pipe" if debug
      puts "Child pid is #{@m.pid}" if debug
    end
    

    def display2D(true_or_false)
      send_command("display2d:#{true_or_false ? "true" : "false"};")
      response = wait_for_input_prompt
      #interpret_response(response)
    end
    
    def set_line_length(line_length)
      send_command("linel:#{line_length};")
      response = wait_for_input_prompt
      #interpret_response(response)
    end
    
    # configure line length and 1D/2D display
    def configure_1D
      display2D(false)
      set_line_length(360)
    end

    def configure_2D
      display2D(true)
      set_line_length(40)
    end

=begin
  # DEPRECATED

    # maybe we could check exited? instead?
    def running?
      pid = nil 
      begin
	pid = @m.pid 
      rescue IOError
      end
      #puts "running? method checking maxima pid:  pid: #{pid.nil? ? 'IOError' : pid}"
      return !pid.nil?  
    end
=end
    
  end
end

  # This can hang the maxima process!!!
  # The input prompt never returns.
  # NOTE:  you can continue sending comands to it even though the input prompt doesn't return...
  # will need to recover from TimeoutException and try sending something else to see if it is really hung.  In the case that it is REALLY hung, 
  # we will need to automatically send quit(); and/or kill backend maxima processes that hang
  # TODO:  develop this infrastructure...
=begin
ammonc@ubuntuserver:~/src/mine/maxima_expect_http_server$ maxima -q

(%i1) tex(x/y); simplify(0) tex(sin(x));
$${{x}\over{y}}$$
(%o1)                                false
incorrect syntax: TEX is not an infix operator
Spacesimplify(0)Spacetex(
               ^

;
incorrect syntax: Premature termination of input at ;.
;
^
;
incorrect syntax: Premature termination of input at ;.
;
^
^CMaxima encountered a Lisp error:

 Console interrupt.

Automatically continuing.
To enable the Lisp debugger set *debugger-hook* to nil.
^CMaxima encountered a Lisp error:

 Console interrupt.

Automatically continuing.
To enable the Lisp debugger set *debugger-hook* to nil.
^C^CMaxima encountered a Lisp error:

 Console interrupt.

Automatically continuing.
To enable the Lisp debugger set *debugger-hook* to nil.
quit();

=end
