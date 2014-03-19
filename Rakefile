require 'rake/testtask'

MIGRATIONS = 'db/migrations'
DATABASE_URL = ENV['DATABASE_URL'] || 'sqlite://ldumbd-test.sqlite3'

Rake::TestTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

namespace :db do
  desc 'Run database migrations'
  task :migrate do
    sh "bundle exec sequel -m #{MIGRATIONS} #{DATABASE_URL}"
  end

  desc 'Drop all tables'
  task :nuke do
    nuke_all_tables = 'DB.tables.each {|t| DB.drop_table?(t) }'
    sh "bundle exec sequel -m #{MIGRATIONS} -M 0 #{DATABASE_URL}"
    sh "bundle exec sequel -c '#{nuke_all_tables}' #{DATABASE_URL}"
  end

  desc 'Reset database'
  task :reset => [:nuke, :migrate]
end
