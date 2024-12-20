# frozen_string_literal: true

RSpec.describe MeetingBuddy::CLI do
  let(:cli) { described_class.new([]) }

  describe "#initialize" do
    it "parses debug flag" do
      cli = described_class.new(["--debug"])
      expect(cli.instance_variable_get(:@options)).to include(debug: true)
    end

    it "parses whisper model" do 
      cli = described_class.new(["-w", "base.en"])
      expect(cli.instance_variable_get(:@options)).to include(whisper_model: "base.en")
    end

    it "parses session name" do
      cli = described_class.new(["-n", "test-session"])
      expect(cli.instance_variable_get(:@options)).to include(name: "test-session")
    end
  end

  describe "#run" do
    let(:session) { instance_double(MeetingBuddy::Session, base_path: Dir.pwd) }

    before do
      allow(MeetingBuddy::Session).to receive(:new).and_return(session)
      allow(session).to receive(:start)
      allow(session).to receive(:stop)
      allow(MeetingBuddy).to receive(:setup)
    end

    it "configures and starts session" do
      expect(MeetingBuddy).to receive(:setup)
      expect(session).to receive(:start)
      allow(cli).to receive(:handle_shutdown)
      cli.run
    end

    it "handles interrupt gracefully" do
      allow(session).to receive(:start).and_raise(Interrupt)
      expect(session).to receive(:stop)
      cli.run
    end
  end
end
