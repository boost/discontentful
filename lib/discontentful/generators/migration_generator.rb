module Discontentful
  module Generators
    class MigrationGenerator < ::Rails::Generators::Base
      argument :name
      source_root File.expand_path('templates', __dir__)

      desc "This generator creates a folder at contentful_migrations/discontentful/ to keep migration files"
      def add_migration
        file_name = name.underscore
        template "templates/migration.erb", "contentful_migrations/discontentful/#{file_name}.rb"
      end
    end
  end
end