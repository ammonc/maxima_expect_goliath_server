# disable by default
#ENV['BENCH'] = "true"
require 'test/test_helper'

class MaximaProcesses < MiniTest::Unit::TestCase
  # Override self.bench_range or default range is [1, 10, 100, 1_000, 10_000]
  
  def self.bench_range 
    #[1, 10, 100, 1_000, 10_000, 100_000]
    [1, 10, 100]  # 1000 is too many
    # What is up with the Invalid argument stuff...
    #[1, 10, 100]
  end
   
  MAXIMA_BASE_CMD = "maxima -q" 
  CMD = "tex(integrate(sin(x)*cos(x),x));"
  CMD_W_NEWLINE = CMD + "\n"
  QUIT = "quit();"
  QUIT_W_NEWLINE = QUIT + "\n"

  def bench_multiple_processes
    assert_performance_linear 0.99 do |n| # n is a range value
      n.times do
        puts n
        @m = IO.popen(MAXIMA_BASE_CMD, "r+")
        @m.puts CMD_W_NEWLINE
        @m.puts QUIT_W_NEWLINE 
        #puts @m.readlines.join
	Process.waitpid(@m.pid, Process::WNOHANG || Process::WUNTRACED)
	stat = $?
	#puts "Child process exited?: #{stat.exited?}" 
	#puts "Child process success?: #{stat.success?}" 
      end
    end
  end

  def bench_single_process
    # maxima -q --batch-string 'tex(integrate(sin(x)*cos(x),x));'
    
    assert_performance_constant 0.99 do |n| # n is a range value
=begin 
# Old way is not quite apples to apples (popen vs system) (and it spends cycles printing to STDOUT)
      cmd_w_newline_n_times = cmd_w_newline * n
      cmd = "maxima -q --batch-string '#{cmd_w_newline_n_times}'"
      puts n
      #puts cmd 
      str = system(cmd)
      #puts str
=end
      @m = IO.popen(MAXIMA_BASE_CMD, "r+")
      n.times do
        @m.puts CMD_W_NEWLINE
      end
      @m.puts QUIT_W_NEWLINE 
      Process.waitpid(@m.pid, Process::WNOHANG || Process::WUNTRACED)
      stat = $?
      #puts "Child process exited?: #{stat.exited?}" 
      #puts "Child process success?: #{stat.success?}" 
    end
  end
end

