# frozen_string_literal: true

require "open3"

module MeetingBuddy
  class Listener
    def initialize(transcriber:, signal:)
      @transcriber = transcriber
      @signal = signal
      @shutdown = false
      @announce_hearing = true
      @whisper_logger = MeetingBuddy.whisper_logger
    end

    def start
      Sync do |parent|
        Open3.popen3(MeetingBuddy.config.whisper_command) do |_stdin, stdout, stderr, _thread|
          error_task = parent.async do
            log_errors(stderr)
          rescue IOError => e
            MeetingBuddy.logger.debug "Error stream closed: #{e.message}"
          end
          output_task = parent.async do
            log_output(stdout)
          rescue IOError => e
            MeetingBuddy.config.logger.debug "Output stream closed: #{e.message}"
          end

          MeetingBuddy.logger.info "Listening..."

          while (line = stdout.gets)
            break if @shutdown
            MeetingBuddy.logger.debug("Shutdown: process_audio_stream...") and break if @shutdown
            begin
              process_transcription(line)
            rescue IOError => e
              MeetingBuddy.config.logger.debug "Main output stream closed: #{e.message}"
            end
          end

          error_task.wait
          output_task.wait
        end
      end
    end

    # Stop the listening process
    def stop
      @shutdown = true
    end

    def announce_what_you_hear!
      @announce_hearing = true
    end

    def suppress_what_you_hear!
      @announce_hearing = false
    end

    private

    def process_transcription(line)
      transcribed_line = @transcriber.process(line)
      return if transcribed_line.text.empty?
      MeetingBuddy.logger.info "Heard: #{transcribed_line.text}" if @announce_hearing
      @signal.trigger({text: transcribed_line.text, timestamp: transcribed_line.timestamp})
    end

    def log_errors(stderr)
      stderr.each { |line| @whisper_logger.error(line) }
    end

    def log_output(stdout)
      stdout.each { |line| @whisper_logger.debug(line) }
    end
  end
end
