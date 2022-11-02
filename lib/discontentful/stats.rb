module Discontentful
  # Stats is responsible for collecting progress information and stats for
  # displaying to the user.
  #
  class Stats
    def initialize
      @stats = {}
      @progress_bar = nil
      @current_record = nil
    end

    def start_progress_bar(title, total)
      @progress_bar = ProgressBar.create(
        title: title.rjust(20),
        total: total,
        format: '%t: %c/%C %a |%B| %E'
      )
    end

    def record_context(record, &block)
      @current_record = record
      yield
      @current_record = nil
      @stats['Processed records'] ||= 0
      @stats['Processed records'] += 1
      @progress_bar.increment
    end

    def end_progress_bar
      @progress_bar.finish
      @progress_bar = nil
    end

    def update_record
      @stats['Updated records'] ||= 0
      @stats['Updated records'] += 1
    end

    def publish_record
      @stats['Published records'] ||= 0
      @stats['Published records'] += 1
    end

    def error(message)
      log Rainbow("[#{@current_record&.id}] Error: #{message}").red
      @stats['Errors'] ||= 0
      @stats['Errors'] += 1
    end

    def warning(message)
      log Rainbow("[#{@current_record&.id}] Warning: #{message}").yellow
      @stats['Warnings'] ||= 0
      @stats['Warnings'] += 1
    end

    def info(message)
      log Rainbow("[#{@current_record&.id}] Info: #{message}").blue
    end

    def log(message = '')
      if @progress_bar.nil?
        puts message
      else
        @progress_bar.log message
      end
    end

    def print_stats
      log
      @stats.each do |stat, value|
        log Rainbow("#{stat}: #{value}").white
      end
    end
  end
end