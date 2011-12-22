task :default => 'test'

# Scripts in test/external run in their own interpreter, but
# need a lib path.

ENV['RUBYLIB'] = File.join(File.dirname(__FILE__), 'lib')

desc "Run tests"
task :test do
  Dir['test/*_test.rb'].each do |test|
    require File.join(File.dirname(__FILE__), test)
  end
end
