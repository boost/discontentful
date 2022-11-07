module Discontentful
  class Railtie < Rails::Railtie
    rake_tasks do
      load "discontentful/tasks/discontentful.tasks"
    end

    generators do
      require "discontentful/generators/migration_generator"
    end
  end
end