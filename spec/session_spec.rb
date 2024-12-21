# frozen_string_literal: true

require "spec_helper"
require "meeting_buddy"

RSpec.describe MeetingBuddy::Session do
  let(:session) { described_class.new }

  describe "#initialize" do
    it "sets default name using timestamp" do
      expect(session.name).to match(/\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}/)
    end

    it "accepts custom assistants" do
      assistant = instance_double("Assistant")
      session = described_class.new(assistants: [assistant])
      expect(session.assistants).to include(assistant)
    end
  end

  describe "#start" do
    let(:mock_listener) { instance_double(MeetingBuddy::Listener) }

    before { allow(MeetingBuddy::Listener).to receive(:new).and_return(mock_listener) }

    it "creates base directory" do
      expect(mock_listener).to receive(:start)
      session.instance_variable_set(:@shutdown, true)
      session.start
      expect(Dir.exist?(session.base_path)).to be true
    end
  end

  describe "#update_transcript" do
    let(:assistant) { double("Assistant", on_transcription: nil) }
    let(:session) { described_class.new(assistants: [assistant]) }

    it "notifies assistants of new transcription" do
      expect(assistant).to receive(:on_transcription).with("test text")
      session.update_transcript("test text")
    end
  end
end
