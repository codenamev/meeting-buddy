# frozen_string_literal: true

require "spec_helper"
require "meeting_buddy"

RSpec.describe MeetingBuddy do
  let(:config) { MeetingBuddy.config }

  describe ".config" do
    it "returns a Configuration instance" do
      expect(MeetingBuddy.config).to be_a(MeetingBuddy::Configuration)
    end

    it "memoizes the configuration" do
      expect(MeetingBuddy.config).to eq(MeetingBuddy.config)
    end
  end

  describe ".configure" do
    it "yields the configuration if a block is given" do
      expect { |b| MeetingBuddy.configure(&b) }.to yield_with_args(MeetingBuddy::Configuration)
    end

    it "creates a new configuration instance" do
      old_config = MeetingBuddy.config
      MeetingBuddy.configure
      expect(MeetingBuddy.config).not_to eq(old_config)
    end
  end

  describe ".setup" do
    before do
      allow(MeetingBuddy::SystemDependency).to receive(:auto_install!)
      allow(MeetingBuddy::SystemDependency).to receive(:resolve_whisper_model)
    end

    it "installs required system dependencies" do
      expect(MeetingBuddy::SystemDependency).to receive(:auto_install!).with(:git)
      expect(MeetingBuddy::SystemDependency).to receive(:auto_install!).with(:sdl2)
      expect(MeetingBuddy::SystemDependency).to receive(:auto_install!).with(:whisper)
      expect(MeetingBuddy::SystemDependency).to receive(:auto_install!).with(:bat)
      MeetingBuddy.setup
    end

    it "resolves the whisper model" do
      expect(MeetingBuddy::SystemDependency).to receive(:resolve_whisper_model).with(MeetingBuddy.config.whisper_model)
      MeetingBuddy.setup
    end
  end

  describe ".logger" do
    it "returns a logger instance" do
      expect(MeetingBuddy.logger).to be_instance_of(Logger)
    end
  end

  describe ".logger=" do
    it "sets the logger" do
      new_logger = instance_double(Logger)
      MeetingBuddy.logger = new_logger
      expect(MeetingBuddy.logger).to eq(new_logger)
      # reset the stub so it cycles on next run
      MeetingBuddy.logger = nil
    end
  end

  describe ".whisper_model" do
    it "returns the whisper model from the configuration" do
      expect(config).to receive(:whisper_model)
      MeetingBuddy.whisper_model
    end
  end

  describe ".whisper_command" do
    it "returns the whisper command from the configuration" do
      expect(config).to receive(:whisper_command)
      MeetingBuddy.whisper_command
    end
  end
end
