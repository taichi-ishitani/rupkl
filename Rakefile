# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

CLEAN << 'coverage'
CLOBBER << '.rspec_status'

RSpec::Core::RakeTask.new(:spec)

unless ENV.key?('CI')
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  require 'bump/tasks'
end

desc 'Run all RSpec code exmaples and collect code coverage'
task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['spec'].execute
end

task default: :spec
