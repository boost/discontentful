module ContentfulTransformationToolkit
  class Transformation
    class_attribute :type_transforms, default: {}

    def self.each_entry_of_type(type_id, &block)
      type_transforms[type_id] = block
    end

    def self.run(environment)
      new(environment).run
    end

    def initialize(environment, dry_run: true, republish: true)
      @environment = environment
      @dry_run = dry_run
      @republish = republish

      @stats = Stats.new
      @updater = ContentfulUpdater.new(@stats, @environment, @dry_run, @republish)
    end

    delegate :info, :warning, :error, :log, to: :@stats

    def run
      type_transforms.each do |type_id, each_block|
        @stats.log
        @stats.log Rainbow("MIGRATING #{type_id.upcase}").white.underline

        source_records = @environment.entries.all(content_type: type_id, limit: 100)
        @stats.log Rainbow("Found #{source_records.total} #{type_id} entries").white
        @stats.start_progress_bar(type_id, source_records.total)
        get_paginated_records(source_records) do |entry|
          @stats.record_context(entry) do
            instance_exec(entry, @updater, &each_block)
          end
        end
        @stats.end_progress_bar
      end
      @stats.print_stats
    end

    private

    def get_paginated_records(source_records, &block)
      loop do
        source_records.each(&block)
        break if source_records.skip + source_records.size >= source_records.total

        source_records = source_records.next_page
      end
    end
  end
end