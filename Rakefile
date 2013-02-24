require "bundler/gem_tasks"
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :viz do
  [ [6, 1, 1],
    [6, 4, 5] ].each do |vars|
    c, q, t = vars
    ENV['C'], ENV['Q'], ENV['T'] = vars.map(&:to_s)
    file = "viz/proco-#{vars.join '-'}.png"
    system %[erb viz/proco.dot.erb | dot -Tpng -o #{file} && open #{file}]
  end
end
