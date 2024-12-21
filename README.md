# MeetingBuddy

MeetingBuddy is a Ruby framework for real-time audio transcription with event handling. It provides core functionality for applications requiring live speech-to-text conversion and processing.

## Installation

```bash
gem install meeting-buddy
```

## Usage

Basic usage with a custom assistant:

```ruby
require 'meeting_buddy'

class MyAssistant < MeetingBuddy::Assistant
  def on_transcription(text)
    puts "Transcribed: #{text}"
  end
end

session = MeetingBuddy::Session.new(
  name: "my-meeting",
  assistants: [MyAssistant.new]
)

session.start
```

### Configuration

```ruby
MeetingBuddy.configure do |config|
  config.whisper_model = "small.en"  # Choose whisper model
  config.root = "path/to/files"      # Set root directory
  config.logger = Logger.new($stdout, level: Logger::DEBUG)
end
```

### Requirements

1. `git` (for whisper.cpp setup)
2. `sdl2` (for audio input)
3. OpenAI token in `OPENAI_ACCESS_TOKEN` env var
4. MacOS (currently supported platform)

## Development

After checking out the repo:

```bash
bin/setup
rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/codenamev/meeting-buddy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/codenamev/meeting-buddy/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Meeting::Buddy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/codenamev/meeting-buddy/blob/main/CODE_OF_CONDUCT.md).
