# frozen_string_literal: true

require "fileutils"

module MeetingBuddy
  # Manages a meeting session
  # @api public
  class Session
    # @return [String] Name of the session
    # @return [String] Base path for session files
    # @return [Array<Object>] List of assistants for the session
    attr_reader :name, :base_path, :assistants

    # Initialize a new Session
    # @param name [String, nil] Optional name for the session
    # @param assistants [Array<Object>] List of assistants to use
    def initialize(name: nil, assistants: [])
      @name = name || Time.now.strftime("%Y-%m-%d_%H-%M-%S")
      @base_path = File.join(MeetingBuddy.cache_dir, "sessions", @name)
      @assistants = assistants
      @signal = MeetingSignal.new
      setup_transcriber
      FileUtils.mkdir_p base_path
      FileUtils.touch(transcript_log)
    end

    # Start the session
    def start
      Sync do |task|
        listener_task = task.async { start_listener }
        @tasks = [
          {name: "Listener", task: listener_task}
        ]
        task.yield until @shutdown
      end
    end

    # Stop the session
    def stop
      @shutdown = true
      @tasks&.each do |task_info|
        MeetingBuddy.config.logger.info "Stopping #{task_info[:name]}..."
        task_info[:task].wait
      end
    end

    # @return [String] Path to transcript log file
    def transcript_log
      File.join(@base_path, "transcript.log")
    end

    # @return [String] Path to whisper log file
    def whisper_log
      File.join(@base_path, "whisper.log")
    end

    # @return [String] Current transcript content
    def current_transcript
      File.exist?(transcript_log) ? File.read(transcript_log) : ""
    end

    # Update the transcript with new text
    # @param text [String] Text to append to transcript
    def update_transcript(text)
      File.open(transcript_log, "a") { |f| f.puts text }
      @assistants.each { |a| a.on_transcription(text) }
    end

    private

    # Set up the transcriber
    def setup_transcriber
      @transcriber = Transcriber.new
      @signal.subscribe { |data| handle_transcription(data) }
    end

    # Handle new transcription data
    # @param data [Hash] Transcription data
    def handle_transcription(data)
      return if data[:text].to_s.empty?

      update_transcript(data[:text])
    end

    # Start the listener
    def start_listener
      @listener = Listener.new(transcriber: @transcriber, signal: @signal)
      @listener.start
    end
  end
end
