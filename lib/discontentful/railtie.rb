module Discontentful
  class Railtie < Rails::Railtie
    rake_tasks do
      load "discontentful/tasks/discontentful.rake"
    end

    generators do
      require "discontentful/generators/migration_generator"
    end
  end
end