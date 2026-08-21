# frozen_string_literal: true

require_relative "lib/praxicraft/version"

Gem::Specification.new do |spec|
  spec.name          = "praxicraft"
  spec.version       = Praxicraft::VERSION
  spec.authors       = ["PraxiCraft"]
  spec.email         = ["support@praxicraft.com"]
  spec.summary       = "Official Ruby SDK for the Praxicraft Assess Public API"
  spec.description   = "Official Ruby client for the Praxicraft Assess Public API."
  spec.homepage      = "https://docs.praxicraft.com/sdks/ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/praxicraft-platform/praxicraft-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/praxicraft-platform/praxicraft-ruby/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
