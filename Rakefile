require "bundler/gem_tasks"
require 'rake/testtask'
require 'fileutils'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :viz do
  FileUtils.chdir(File.expand_path('..', __FILE__))

  [ [6, 1, 5],
    [6, 1, 1],
    [6, 4, 5] ].each do |vars|
    c, q, t = vars
    ENV['C'], ENV['Q'], ENV['T'] = vars.map(&:to_s)
    file = "viz/proco-#{vars.join '-'}.png"
    system %[erb viz/proco.dot.erb | dot -Tpng -o #{file} && open #{file}]
  end

  %w[producer-consumer proco-lifecycle].each do |file|
    system %[dot -Tpng -o viz/#{file}.png viz/#{file}.dot && open viz/#{file}.png]
  end
end
