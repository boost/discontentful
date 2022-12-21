module Discontentful
  class ContentfulUpdater
    def initialize(stats, environment, tag_name: , dry_run: true, republish: true)
      @stats = stats
      @environment = environment
      @dry_run = dry_run
      @republish = republish
      @tag_name = tag_name
    end

    def update_entry(entry, **fields)
      changed_fields = find_changed_fields(entry, fields)

      return unless changed_fields.any?

      @stats.log Rainbow("Updates #{entry.sys[:contentType].id} [#{entry.id}]").cyan
      display_diff(entry, changed_fields)

      @stats.update_record

      return if @dry_run

      republish(entry) do
        add_tag(entry, @tag_name)
        entry.update(**changed_fields)
        @stats.info "Updated #{entry.id}"
      end
    end

    def create_entry(content_type, **fields)
      type = @environment.content_types.find(content_type)

      @stats.log Rainbow("Creates new #{type.id}").cyan
      fields.each do |field, value|
        @stats.log Rainbow("#{field}:").cyan
        @stats.log Rainbow(value).green
      end

      @stats.create_record

      return if @dry_run

      entry = type.entries.create(**fields)
      add_tag(entry, @tag_name)
      @stats.info "Created #{entry.id}"
    end

    def find_assets(**fields)
      @environment.assets.all(**fields.transform_keys {|k| "fields.#{k}"})
    end

    def find_entries(**fields)
      @environment.entries.all(**fields.transform_keys {|k| "fields.#{k}"})
    end

    def add_tag(entry, tag_name)
      tag_id = tag_name.tr(' ', '_').camelize
      existing_tag = @environment.tags.find(tag_id)
      if existing_tag.is_a?(Contentful::Management::NotFound)
        @environment.tags.create(name: "Migration: #{tag_name}", id: tag_id, visibility: 'private')
      end
      tag_refs = entry._metadata[:tags].map(&:raw_object) + [{ 'sys': { 'type': 'Link', 'linkType': 'Tag', 'id': tag_id } }]
      entry.update(_metadata: { tags: tag_refs })
    end

    private

    def republish(entry)
      updated = entry.updated?

      yield
      return unless @republish && entry.published? && !updated

      add_tag(entry, "#{@tag_name}_repub")
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