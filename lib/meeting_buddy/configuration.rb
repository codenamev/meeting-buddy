# frozen_string_literal: true

module MeetingBuddy
  # Manages configuration for MeetingBuddy
  # @api public
  class Configuration
    # @return [String] Model name for Whisper speech recognition
    attr_accessor :whisper_model

    # @return [OpenAI::Client] OpenAI client instance
    # @return [Logger] Main logger instance
    # @return [Logger] Whisper-specific logger instance
    attr_writer :openai_client, :logger, :whisper_logger

    # Initialize a new Configuration instance
    def initialize
      @logger = Logger.new($stdout, level: Logger::INFO)
      @whisper_model = "small.en-q5_1"
    end

    # @return [Logger] Main logger instance
    def logger
      @logger ||= Logger.new($stdout, level: Logger::INFO)
    end

    # @return [Logger] Whisper-specific logger instance
    def whisper_logger
      @whisper_logger ||= Logger.new(MeetingBuddy.session.whisper_log, level: Logger::INFO)
    end

    # @return [OpenAI::Client] OpenAI client instance
    # @raise [Error] if OPENAI_ACCESS_TOKEN environment variable is not set
    def openai_client
      raise Error, "Please set an OPENAI_ACCESS_TOKEN environment variable." if ENV["OPENAI_ACCESS_TOKEN"].to_s.strip.empty?

      @openai_client ||= OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"], log_errors: true)
    end

    # @return [String] Command to run Whisper speech recognition
    def whisper_command
      "#{MeetingBuddy.cache_dir}/whisper.cpp/build/bin/stream -m #{MeetingBuddy.cache_dir}/whisper.cpp/models/ggml-#{whisper_model}.bin -t 8 --step 0 --length 5000 --keep 500 --vad-thold 0.75 --audio-ctx 0 --keep-context -c 1 -l en"
    end
  end
end
