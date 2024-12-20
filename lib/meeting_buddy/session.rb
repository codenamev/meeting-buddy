# frozen_string_literal: true

require "fileutils"

module MeetingBuddy
  # Manages session-specific data for MeetingBuddy
  class Session
    attr_reader :name, :base_path, :handlers

    def initialize(name: nil, handlers: [])
      @name = name || Time.now.strftime("%Y-%m-%d_%H-%M-%S")
      @base_path = File.join(MeetingBuddy.cache_dir, "sessions", @name)
      @handlers = handlers
      @signal = MeetingSignal.new
      setup_transcriber
      FileUtils.mkdir_p base_path
      FileUtils.touch(transcript_log)
    end

    def start
      Sync do |task|
        listener_task = task.async { start_listener }
        @tasks = [
          {name: "Listener", task: listener_task}
        ]
        task.yield until @shutdown
      end
    end

    def stop
      @shutdown = true
      @tasks&.each do |task_info|
        MeetingBuddy.config.logger.info "Stopping #{task_info[:name]}..."
        task_info[:task].wait
      end
    end

    def transcript_log
      File.join(@base_path, "transcript.log")
    end

    def whisper_log
      File.join(@base_path, "whisper.log")
    end

    def current_transcript
      File.exist?(transcript_log) ? File.read(transcript_log) : ""
    end

    def update_transcript(text)
      File.open(transcript_log, "a") { |f| f.puts text }
      @handlers.each { |h| h.on_transcription(text) }
    end

    private

    def setup_transcriber
      @transcriber = Transcriber.new
      @signal.subscribe { |data| handle_transcription(data) }
    end

    def handle_transcription(data)
      return if data[:text].to_s.empty?

      update_transcript(data[:text])
    end

    def start_listener
      @listener = Listener.new(transcriber: @transcriber, signal: @signal)
      @listener.start
    end
  end
end
