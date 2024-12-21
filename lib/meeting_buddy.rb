# frozen_string_literal: true

require "logger"
require "async"
require "async/http/faraday"
require "rainbow"
require "openai"

require_relative "meeting_buddy/version"
require_relative "meeting_buddy/configuration"
require_relative "meeting_buddy/listener"
require_relative "meeting_buddy/meeting_signal"
require_relative "meeting_buddy/session"
require_relative "meeting_buddy/system_dependency"
require_relative "meeting_buddy/transcriber"
require_relative "meeting_buddy/cli"

# Main module for MeetingBuddy functionality
# @api public
module MeetingBuddy
  # Base error class for MeetingBuddy-specific errors
  class Error < StandardError; end

  class << self
    # @return [Session] Current active session
    attr_accessor :session

    extend Forwardable
    def_delegators :config,
      :logger,
      :logger=,
      :whisper_command,
      :whisper_model,
      :whisper_logger,
      :whisper_logger=,
      :openai_client,
      :openai_client=

    # @return [Configuration] Current configuration instance
    def config
      @config ||= Configuration.new
    end

    # Configure the MeetingBuddy framework
    # @yield [config] Configuration instance
    # @example
    #   MeetingBuddy.configure do |config|
    #     config.whisper_model = "small.en"
    #   end
    def configure
      @config = Configuration.new
      yield(@config) if block_given?
    end

    # Start a new meeting session
    # @param name [String, nil] Optional name for the session
    # @return [Session] New session instance
    def start_session(name: nil)
      @session = Session.new(name: name)
    end

    # @return [String] Path to cache directory
    def cache_dir
      @cache_dir ||= "#{ENV["HOME"]}/.buddy"
    end

    # Set up required system dependencies
    def setup
      Dir.mkdir cache_dir unless Dir.exist?(cache_dir)
      SystemDependency.auto_install!(:git)
      SystemDependency.auto_install!(:sdl2)
      SystemDependency.auto_install!(:whisper)
      SystemDependency.auto_install!(:bat)
      SystemDependency.resolve_whisper_model(whisper_model)
    end

    # Format text for human display with optional color
    # @param text [String] Text to format
    # @param label [Symbol] Type of formatting to apply (:info, :wait, :input, :success)
    # @return [String] Formatted text
    def to_human(text, label = :info)
      case label.to_sym
      when :info
        Rainbow(text).blue
      when :wait
        Rainbow(text).yellow
      when :input
        Rainbow(text).black.bg(:yellow)
      when :success
        Rainbow(text).green
      else
        text
      end
    end
  end

  configure
end
