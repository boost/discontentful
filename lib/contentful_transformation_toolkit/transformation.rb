module ContentfulTransformationToolkit
  class Transformation
    class_attribute :type_transforms, default: {}

    def self.each_entry_of_type(type_id, &block)
      self.type_transforms[type_id] = block
    end

    def self.run(environment)
      new(environment).run
    end

    def initialize(environment, dry_run: true, republish: true)
      @environment = environment
      @dry_run = dry_run
      @republish = republish
      @progess_bar = nil

      @stats = {}
    end

    def run
      self.type_transforms.each do |type_id, each_block|
        log
        log Rainbow("MIGRATING #{type_id.upcase}").white.underline

        source_records = @environment.entries.all(content_type: type_id, limit: 100)
        log Rainbow("Found #{source_records.total} #{type_id} entries").white
        @progress_bar = ProgressBar.create(title: type_id.rjust(20), total: source_records.total, format: '%t: %c/%C %a |%B| %E')
        loop do
          source_records.each do |entry|
            @current_record = entry
            instance_exec(entry, &each_block)
            @stats['Processed records'] ||= 0
            @stats['Processed records'] += 1
            @progress_bar.increment
            @current_record = nil
          end
          break if source_records.skip + source_records.size >= source_records.total

          source_records = source_records.next_page
        end
        @progress_bar.finish
        @progress_bar = nil
        print_stats
      end
    end

    private

    def error(message)
      log Rainbow("[#{@current_record.id}] Error: #{message}").red
      @stats['Errors'] ||= 0
      @stats['Errors'] += 1
    end

    def warning(message)
      log Rainbow("[#{@current_record.id}] Warning: #{message}").yellow
      @stats['Warnings'] ||= 0
      @stats['Warnings'] += 1
    end

    def info(message)
      log Rainbow("[#{@current_record.id}] Info: #{message}").blue
    end

    def log(message = '')
      if @progress_bar.nil?
        puts message
      else
        @progress_bar.log message
      end
    end

    def print_stats
      @stats.each do |stat, value|
        log Rainbow("#{stat}: #{value}").white
      end
    end

    def update_entry_by_locale(entry, locale, **fields)
      entry.locale = locale
      changed_fields = fields.select do |field_name, new_value|
        existing = entry.public_send(field_name)
        new_value != existing
      end.to_h

      return unless changed_fields.any?

      log Rainbow("Updates #{entry.sys[:contentType].id} [#{entry.id}] locale #{locale}").cyan
      changed_fields.each do |field_name, new_value|
        existing = entry.public_send(field_name)
        log Rainbow("#{field_name}:").cyan
        log diff(existing, new_value)
      end

      @stats['Updated records'] ||= 0
      @stats['Updated records'] += 1

      unless @dry_run
        was_published = entry.published?
        entry.update(**changed_fields)
        info "Updated #{entry.id}"
        if @republish && was_published
          response = entry.publish
          if response.is_a? Contentful::Management::Error
            error "There was an error republishing #{entry.id}: #{response.message}"
          else
            info "Republished #{entry.id}"
          end
        end
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

    def find_assets(**fields)
      @environment.assets.all(**fields.transform_keys {|k| "fields.#{k}"})
    end

    def find_entries(**fields)
      @environment.entries.all(**fields.transform_keys {|k| "fields.#{k}"})
    end
  end
end