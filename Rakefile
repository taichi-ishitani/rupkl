# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

unless ENV.key?('CI')
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  require 'bump/tasks'
end

task default: :spec
