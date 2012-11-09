#!/usr/bin/env rake
require "bundler/gem_tasks"

task :console do
  require "pp"
  require "irb"

  require "object_momma"
  ObjectMomma.mullet!

  require File.join(File.dirname(__FILE__), "spec/fixtures/blog_post_voting_classes")

  ARGV.clear
  IRB.start
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new('spec')

task :default => :spec
