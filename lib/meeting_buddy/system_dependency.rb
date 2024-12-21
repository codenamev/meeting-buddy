# frozen_string_literal: true

module MeetingBuddy
  # Manages system dependencies for MeetingBuddy
  # @api private
  class SystemDependency < Struct.new(:name, keyword_init: true)
    # Current version of whisper.cpp to use
    WHISPER_CPP_VERSION = "v1.7.3"

    # @return [Symbol] Name of the dependency
    attr_accessor :name

    class << self
      # Automatically install a system dependency if not present
      # @param name [Symbol] Name of the dependency to install
      def auto_install!(name)
        system_dependency = new(name: name)
        system_dependency.install unless system_dependency.installed?
      end

      # Ensure the specified Whisper model is available
      # @param model [String] Name of the model to resolve
      def resolve_whisper_model(model)
        return if model_downloaded?(model)
        download_model(model)
      end

      # Check if a Whisper model is already downloaded
      # @param model [String] Name of the model to check
      # @return [Boolean] true if model exists
      def model_downloaded?(model)
        File.exist?(File.join(MeetingBuddy.cache_dir, "whisper.cpp", "models", "ggml-#{model}.bin"))
      end

      # Download a Whisper model
      # @param model [String] Name of the model to download
      def download_model(model)
        Dir.chdir("#{MeetingBuddy.cache_dir}/whisper.cpp") do
          MeetingBuddy.logger.info "Downloading GGML model: #{MeetingBuddy.whisper_model}"
          MeetingBuddy.logger.info `bash ./models/download-ggml-model.sh #{MeetingBuddy.whisper_model}`
        end
      end
    end

    # Initialize a new SystemDependency instance
    # @param name [Symbol] Name of the dependency
    def initialize(name:)
      @name = name
    end

    # Check if the dependency is installed
    # @return [Boolean] true if installed
    def installed?
      MeetingBuddy.logger.info "Checking for system dependency: #{name}..."
      if name.to_s == "whisper"
        Dir.exist?("#{MeetingBuddy.cache_dir}/whisper.cpp")
      else
        system("brew list -1 #{name} > /dev/null") || system("type -a #{name}")
      end
    end

    # Install the dependency
    def install
      return install_whisper if name.to_s == "whisper"

      MeetingBuddy.logger.info "Installing #{name}..."
      `brew list #{name} || brew install #{name}`
    end

    private

    # Install whisper.cpp
    def install_whisper
      MeetingBuddy.logger.info "Installing whisper.cpp..."
      Dir.chdir(MeetingBuddy.cache_dir) do
        MeetingBuddy.logger.info "Setting up whipser.cpp in #{MeetingBuddy.cache_dir}/whipser.cpp"
        MeetingBuddy.logger.info `git clone https://github.com/ggerganov/whisper.cpp`
        Dir.chdir("whisper.cpp") do
          MeetingBuddy.logger.info `git checkout #{WHISPER_CPP_VERSION}`
          MeetingBuddy.logger.info "Downloading GGML model: #{MeetingBuddy.whisper_model}"
          MeetingBuddy.logger.info `bash #{MeetingBuddy.cache_dir}/whisper.cpp/models/download-ggml-model.sh #{MeetingBuddy.whisper_model}`
          MeetingBuddy.logger.info "Building whipser.cpp with streaming support..."
          MeetingBuddy.logger.info `cmake -B build -DWHISPER_SDL2=ON && cmake --build build --config Release`
        end
      end
    end
  end
end
