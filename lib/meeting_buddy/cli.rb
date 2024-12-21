# frozen_string_literal: true

require "optparse"
require "rainbow"

module MeetingBuddy
  # Command Line Interface for MeetingBuddy
  # @api public
  class CLI
    # Initialize a new CLI instance
    # @param argv [Array<String>] Command line arguments
    def initialize(argv)
      @options = parse_options(argv)
    end

    # Run the CLI
    def run
      configure
      setup_dependencies
      start_session
    rescue Interrupt
      handle_shutdown
    end

    private

    # Parse command line options
    # @param argv [Array<String>] Command line arguments
    # @return [Hash] Parsed options
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

    # Configure MeetingBuddy based on options
    def configure
      MeetingBuddy.configure do |config|
        config.whisper_model = @options[:whisper_model] if @options[:whisper_model]
        config.logger.level = @options[:debug] ? Logger::DEBUG : Logger::INFO
        config.logger.formatter = proc do |severity, datetime, progname, msg|
          (severity.to_s == "INFO") ? "#{msg}\n" : "[#{severity}] #{msg}\n"
        end
      end
    end

    # Set up system dependencies
    def setup_dependencies
      MeetingBuddy.logger.info "Setting up dependencies..."
      MeetingBuddy.setup
      MeetingBuddy.logger.info "Setup complete."
      MeetingBuddy.openai_client
    end

    # Start a new session
    def start_session
      MeetingBuddy.start_session(name: @options[:name])
      MeetingBuddy.logger.info MeetingBuddy.to_human("Using whisper model: #{MeetingBuddy.config.whisper_model}", :info)
      MeetingBuddy.logger.info MeetingBuddy.to_human("Starting session in: #{MeetingBuddy.session.base_path}", :info)
      MeetingBuddy.session.start
    end

    # Handle shutdown gracefully
    def handle_shutdown
      MeetingBuddy.logger.info MeetingBuddy.to_human("\nShutting down streams...", :wait)
      MeetingBuddy.session.stop
    end
  end
end
