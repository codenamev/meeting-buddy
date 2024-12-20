# frozen_string_literal: true

module MeetingBuddy
  # Manages configuration for MeetingBuddy
  class Configuration
    attr_accessor :whisper_model
    attr_writer :openai_client, :logger, :whisper_logger

    def initialize
      @logger = Logger.new($stdout, level: Logger::INFO)
      @whisper_model = "small.en-q5_1"
    end

    def logger
      @logger ||= Logger.new($stdout, level: Logger::INFO)
    end

    def whisper_logger
      @whisper_logger ||= Logger.new(MeetingBuddy.session.whisper_log, level: Logger::INFO)
    end

    # @return [OpenAI::Client]
    def openai_client
      raise Error, "Please set an OPENAI_ACCESS_TOKEN environment variable." if ENV["OPENAI_ACCESS_TOKEN"].to_s.strip.empty?

      @openai_client ||= OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"], log_errors: true)
    end

    # @return [String]
    def whisper_command
      "#{MeetingBuddy.cache_dir}/whisper.cpp/build/bin/stream -m #{MeetingBuddy.cache_dir}/whisper.cpp/models/ggml-#{whisper_model}.bin -t 8 --step 0 --length 5000 --keep 500 --vad-thold 0.75 --audio-ctx 0 --keep-context -c 1 -l en"
    end
  end
end
