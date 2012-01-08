RUBY = "ruby -I ."
watch('test/test_.*\.rb') {|m| system("#{RUBY} #{m[0]}")}
watch('lib/(.*)\.rb') {|m| system("#{RUBY} test/test_#{m[1]}.rb"}
