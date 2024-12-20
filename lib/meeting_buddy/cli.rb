# frozen_string_literal: true

require "optparse"
require "rainbow"

module MeetingBuddy
  # Command Line Interface for MeetingBuddy
  #
  # Handles command line argument parsing, session management, and audio processing
  # for meeting recording and AI interaction.
  #
  # @example Basic usage
  #   cli = MeetingBuddy::CLI.new(ARGV)
  #   cli.run
  #
  # @example With options
  #   cli = MeetingBuddy::CLI.new(["--debug", "-n", "my-meeting"])
  #   cli.run
  class CLI
    def initialize(argv)
      @options = parse_options(argv)
    end

    def run
      configure
      setup_dependencies
      start_session
    rescue Interrupt
      handle_shutdown
    end

    private

    def parse_options(argv)
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: meeting_buddy [options]"

        opts.on("--debug", "Run in debug mode") do |v|
          options[:debug] = v
        end

        opts.on("-w", "--whisper MODEL", "Use specific whisper model (default: small.en)") do |v|
          options[:whisper_model] = v
        end

        opts.on("-n", "--name NAME", "A name for the session to label all log files") do |v|
          options[:name] = v
        end
      end.parse!(argv)
      options
    end

    def configure
      MeetingBuddy.configure do |config|
        config.whisper_model = @options[:whisper_model] if @options[:whisper_model]
        config.logger.level = @options[:debug] ? Logger::DEBUG : Logger::INFO
        config.logger.formatter = proc do |severity, datetime, progname, msg|
          (severity.to_s == "INFO") ? "#{msg}\n" : "[#{severity}] #{msg}\n"
        end
      end
    end

    def setup_dependencies
      MeetingBuddy.logger.info "Setting up dependencies..."
      MeetingBuddy.setup
      MeetingBuddy.logger.info "Setup complete."
      MeetingBuddy.openai_client
    end

    def start_session
      MeetingBuddy.start_session(name: @options[:name])
      MeetingBuddy.logger.info MeetingBuddy.to_human("Using whisper model: #{MeetingBuddy.config.whisper_model}", :info)
      MeetingBuddy.logger.info MeetingBuddy.to_human("Starting session in: #{MeetingBuddy.session.base_path}", :info)
      MeetingBuddy.session.start
    end

    def handle_shutdown
      MeetingBuddy.logger.info MeetingBuddy.to_human("\nShutting down streams...", :wait)
      MeetingBuddy.session.stop
    end
  end
end
