module ContentfulTransformationToolkit
  class ContentfulUpdater
    def initialize(stats, environment, dry_run, republish)
      @stats = stats
      @environment = environment
      @dry_run = dry_run
      @republish = republish
    end

    def update_entry(entry, **fields)
      changed_fields = find_changed_fields(entry, fields)

      return unless changed_fields.any?

      @stats.log Rainbow("Updates #{entry.sys[:contentType].id} [#{entry.id}]").cyan
      display_diff(entry, changed_fields)

      @stats.update_record

      return if @dry_run

      entry.update(**changed_fields)
      @stats.info "Updated #{entry.id}"
      republish(entry)
    end

    def find_assets(**fields)
      @environment.assets.all(**fields.transform_keys {|k| "fields.#{k}"})
    end

    def find_entries(**fields)
      @environment.entries.all(**fields.transform_keys {|k| "fields.#{k}"})
    end

    private

    def republish(entry)
      return unless @republish && entry.published? # state before update

      response = entry.publish
      if response.is_a? Contentful::Management::Error
        @stats.error "There was an error republishing #{entry.id}: #{response.message}"
      else
        @stats.info "Republished #{entry.id}"
      end
    end

    def find_changed_fields(entry, field_updates)
      field_updates.reject do |field_name, new_value|
        existing = entry.public_send(field_name)
        new_value == existing
      end.to_h
    end

    def display_diff(entry, fields)
      fields.each do |field_name, new_value|
        existing = entry.public_send(field_name)
        @stats.log Rainbow("#{field_name}:").cyan
        @stats.log diff(existing, new_value)
      end
    end

    def diff(*vals)
      vals_as_string = vals.map do |val|
        if val.is_a? Hash
          val.to_yaml
        else
          val.to_s
        end
      end
      Diffy::Diff.new(*vals_as_string, context: 10).to_s(:color)
    end
  end
end