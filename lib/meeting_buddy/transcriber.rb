# frozen_string_literal: false

module MeetingBuddy
  # Manages the transcript of the meeting
  # @api private
  class Transcriber
    # @return [String] full transcript of the meeting
    attr_reader :full_transcript

    # Represents a single line of transcription
    # @api private
    class Line < Struct.new(:text, :timestamp, keyword_init: true); end

    # Initialize a new Transcriber instance
    def initialize
      @full_transcript = ""
      @last_timestamp = 0
    end

    # Process new transcription text
    # @param line [String] raw transcription line from whisper
    # @return [Line] processed transcription line
    def process(line)
      timestamp, text = parse_line(line)
      return Line.new(text: "", timestamp: Time.now) if text.empty?

      @full_transcript += text
      @last_timestamp = timestamp

      Line.new(text: format_transcription(text), timestamp: @last_timestamp)
    end

    # Get the latest portion of the transcript
    # @param limit [Integer] number of characters to return
    # @return [String] latest portion of the transcript
    # @raise [ArgumentError] if limit is negative
    def latest(limit = 200)
      @full_transcript[[@full_transcript.length - limit, 0].max, limit] || raise(ArgumentError, "negative limit")
    end

    private

    # Format transcription text for output
    # @param text [String] raw transcription text
    # @return [String] formatted text
    def format_transcription(text)
      text.strip + " "
    end

    # Parse a raw transcription line
    # @param line [String] raw line from whisper
    # @return [Array<Integer, String>] timestamp and cleaned text
    def parse_line(line)
      timestamp, text = nil, ""
      match = line.match(/\[.*?(\d{2}:\d{2}:\d{2}\.\d{3}).*?\]\s{1,3}(.+)/)
      timestamp, text = [match[1].to_i, match[2]] if match
      text.gsub!(/(\[BLANK_AUDIO\]|\A\["\s?|"\]\Z)/, "")&.strip
      text.concat(" ") if text.match?(/[^\w\s]\Z/)
      [timestamp, text]
    end

    # Convert time string to seconds
    # @param time_str [String] time in format 'h:m:s'
    # @return [Float] time in seconds
    def time_to_seconds(time_str)
      h, m, s = time_str.split(":").map(&:to_f)
      (h * 3600) + (m * 60) + s
    end
  end
end
