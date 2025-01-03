# frozen_string_literal: true

require_relative "lib/meeting_buddy/version"

Gem::Specification.new do |spec|
  spec.name = "meeting-buddy"
  spec.version = MeetingBuddy::VERSION
  spec.authors = ["Valentino Stoll"]
  spec.email = ["v@codenamev.com"]

  spec.summary = "A simple Ruby command-line framework for dropping an AI buddy into your meeting."
  spec.description = "A simple Ruby command-line framework for dropping an AI buddy into your meeting."
  spec.homepage = "https://github.com/codenamev/meeting-buddy"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/codenamev/meeting-buddy"
  spec.metadata["changelog_uri"] = "https://github.com/codenamev/meeting-buddy/tree/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "async"
  spec.add_dependency "async-http-faraday"
  spec.add_dependency "ruby-openai"
  spec.add_dependency "rainbow"
end
