
module Maxima
  class ResultClobberException < RuntimeError
  end

  class NoIterationException < RuntimeError
  end

=begin
Two things to note here:
1. the input prompt number remains the same, it doesn't increment
2. the statement after the semicolon after the syntax error isn't processed (it could depend on the previous part with the syntax error);
  a. Therefore, this can be a greedy match!

$ maxima -q

(%i1) display2d:false;

(%o1) false
(%i2) simplify(x^3-x^3) 1;tex(integrate(x,x));"
incorrect syntax: 1 is not an infix operator
simplify(x^3-x^3)Space1;
                  ^
(%i2)
=end  
  class NoMatchException < RuntimeError
  end

  # Could have multiple commands 
  # either from 
  #   1. allowing multiple commands to be processed at a time (separated by ; or $) OR
  #      a. in which case we *need* to process all of them before sending back the response to the client
  #   2. sending multiple commands to maxima before being able to "expect" the first and having multiple commands in the buffer at once
  #      a. we can send a response back to the client as soon as we have the one(s) that belong(s) to that request
  #      
  # So in either case, we need to know how many responses we are expecting.  
  #   a. we can count the number of $ and ; in a request
  # It sounds like we need to maintain a buffer of maxima expect match strings and a hash of responses per input number ($ ones won't have a %o7 or an output string at all)
  class MatchProcessor
    FIRST_INPUT_PROMPT_REGEX = /(.*?)\(%i(\d+)\)/m  # across multiple lines, non-greedy match of everything up to and including the input number
   
    # Notice use of non-greedy .* in case we get more than one response at a time
    

=begin
    TEX_RESPONSE_REGEX = /(\$\$.*?\$\$)\s+\(%o\d+\)\s+false\s+\(%i\d+\)/m  
    NON_TEX_RESPONSE_REGEX = /.*?\(%o\d+\)\s+(.*?)\(%i\d+\)/m 
    # No output number part on the syntax error
    # Example:  "incorrect syntax: TEX is not an infix operator\nmplify(x^3-x^3)Spacetex(\n                  ^\n(%i3)"
    SYNTAX_ERROR_RESPONSE_REGEX = /incorrect syntax:(.*?)\(%i\d+\)/mi  
=end    

    TEX_RESPONSE_REGEX = /(\$\$.*?\$\$)\s+\(%o(\d+)\)\s+false/m  
    NON_TEX_RESPONSE_REGEX = /.*?\(%o(\d+)\)\s+(.*?)\n/m
 
    # No output number part on the syntax error
    # Example:  "incorrect syntax: TEX is not an infix operator\nmplify(x^3-x^3)Spacetex(\n                  ^\n(%i3)"
    # Greedy on purpose (no semicolon or $ separated commands after it are executed)
    SYNTAX_ERROR_RESPONSE_REGEX = /(incorrect syntax:.*)/mi  

    attr_reader :results

    def debug 
      true
    end


    def initialize(match_arr)
      @results = {}
      
      match_arr.each do |matching_str|
        matching_str_work = matching_str.dup

        # do I need chomp and strip or just strip?  just strip
        #    irb(main):001:0> s = "45 / 3 \t \n\r\n\t"
        #    => "45 / 3 \t \n\r\n\t"
        #    irb(main):002:0> s.strip
        #    => "45 / 3"
        #    irb(main):003:0>
        matching_str_work.strip!

        num_iterations = 0
        
        # expect could give us multiple matches, but our current regex is only set up to get one match
        # but this while loop is here to keep it generic... 
        while ( matches = matching_str_work.match(FIRST_INPUT_PROMPT_REGEX) ) do
          full_match = matches[0]

          raw_result_str   = matches[1]
          input_number_str = matches[2]
          input_number = input_number_str.to_i

          if debug
            puts "raw_result_str: #{raw_result_str.inspect}"
            puts "input_number: #{input_number.inspect}"
          end

          part_match = nil
          matches = nil
          
          raw_result_str_work   = raw_result_str.dup 
          result_str = nil
          begin  # start of do until loop
	    puts "Here0"
            # need to pick the match that occurs first in the string, not prioritize one type of match over the other... 
            
            # choose the minimum, non-nil regex match index into the match string
            regexes = [TEX_RESPONSE_REGEX, NON_TEX_RESPONSE_REGEX, SYNTAX_ERROR_RESPONSE_REGEX]
            match_positions = regexes.collect { |r| raw_result_str_work =~ r }
            index_to_first_matching_regex = match_positions.size
            for i in 0...match_positions.size do
              next if match_positions[i].nil?
              index_to_first_matching_regex = i if match_positions[i] < index_to_first_matching_regex 
            end
            
            puts raw_result_str_work.inspect
            puts match_positions.inspect
            puts index_to_first_matching_regex
            
            if (index_to_first_matching_regex == regexes.index(TEX_RESPONSE_REGEX))
              matches = raw_result_str_work.match(TEX_RESPONSE_REGEX)
              part_match = matches[0]
              result_str = matches[1]
              result_str.strip!
	      output_number_str = matches[2]
	      output_number = output_number_str.to_i
              if debug
                puts "Matched tex:"
                puts result_str.inspect
              end
            elsif (index_to_first_matching_regex == regexes.index(NON_TEX_RESPONSE_REGEX))
              matches = raw_result_str_work.match(NON_TEX_RESPONSE_REGEX)
              part_match = matches[0]
	      output_number_str = matches[1]
	      output_number = output_number_str.to_i
              result_str = matches[2]
              result_str.strip!
              if debug
                puts "Matched non-tex:"
                puts result_str.inspect
              end
            elsif (index_to_first_matching_regex == regexes.index(SYNTAX_ERROR_RESPONSE_REGEX)) 
              matches = raw_result_str_work.match(SYNTAX_ERROR_RESPONSE_REGEX)
              part_match = matches[0]
              result_str = matches[1]
              result_str.strip!
              # output_number is not specified for syntax errors, but we do want to collect each syntax error in order.  
              # 0 may be incorrect, but is always before the first input/output number of 1
              error_output_number = nil
              if output_number.nil?
                error_output_number = 0
              else
                error_output_number = output_number + 1
              end
              output_number = error_output_number
              if debug
                puts "Matched syntax error regex:"
                puts result_str.inspect
              end
              # I think that instead of raising an exception and halting processing all of the commands in the result set, we'll just put the syntax error text in the result hash and move on to the next match...
              
              # TODO:
              # Hard to know when syntax error should end
              # I guess it would end with the line before $$ for tex or %o\d+ for a non-tex response or with incorrect syntax (if two back to back syntax errors
              # DONE:  NOTE: Even if independent, syntactically correct statement after the syntax error, maxima will NOT execute them, so we just let the greedy match get the rest of the output
              
              raise SyntaxError, result_str
            else
              part_match = raw_result_str_work
              result_str = raw_result_str_work
              raise NoMatchException, raw_result_str_work
            end
          
            puts "output_number: #{output_number}" if debug
 
            key_already_exists = !@results[output_number].nil?
            raise ResultClobberException if key_already_exists
            @results[output_number] = result_str


            # removes the range of characters from the string
            raw_result_str_work.slice!(0...part_match.size)

            # clear the string ONLY if all that is left is whitespace (some regexes need whitespace termination to sense the end of the match, so we can't just remove it all the time)
            raw_result_str_work.strip! if raw_result_str_work =~ /^\s+$/

            num_iterations += 1
            if debug
              puts "Partial string part left:"
              puts raw_result_str_work.inspect
            end

	    puts "Here1"
	    puts raw_result_str_work.inspect

          end until raw_result_str_work.empty?
          
          # we need this so that when the inner loop finds its group of output prompts for this input prompt to be empty that the matches = matching_str_work.match(FIRST_INPUT_PROMPT_REGEX) can exit 
          matching_str_work.slice!(0...full_match.size)
          matching_str_work.strip!
          puts "Here2"
          puts matching_str_work.inspect
        end

        
        raise NoIterationException if num_iterations == 0
      end
    end
  end

  
end
