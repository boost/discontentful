# frozen_string_literal: true

namespace :discontentful do

  desc 'Run a discontentful migration found in contentful_migrations/discontentful'
  task :migrate, [:migration_name] do |_task, args|
    require 'highline'

    unless File.exist? 'contentful_migrations/discontentful'
      abort("Expected contentful_migrations/discontentful/ folder for migrations")
    end

    file_name = args[:migration_name].underscore
    require "contentful_migrations/discontentful/#{file_name}"

    class_name = begin
      DiscontentfulMigrations.const_get(args[:migration_name].classify)
    rescue NameError
      abort("Expected contentful_migrations/discontentful/#{file_name}.rb to define DiscontentfulMigrations::#{args[:name].classify}")
    end

    environment = Discontentful.get_environment

    cli = HighLine.new
    cli.say(Rainbow("Do you want to apply changes to contentful?").yellow)
    mode = cli.choose('Apply changes', 'Dry run')
    dry_run = mode != 'Apply changes'

    republish = cli.agree(Rainbow("Republish published entries? (y/n)").yellow) { |e| e.default = true } unless @dry_run

    unless @dry_run
      abort unless cli.agree(Rainbow("You are about to make updates to contentful data! #{Rainbow("Proceed? (y/n)").yellow}").red)
    end

    class_name.new(environment, dry_run: dry_run, republish: republish)
  end
end