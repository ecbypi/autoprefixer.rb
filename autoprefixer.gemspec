Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "autoprefixer"
  s.version = "0.0.1"
  s.summary = "Autoprefixer in ruby"
  s.authors = ["Eduardo Gutierrez"]

  s.homepage = "https://github.com/ecbypi/autoprefixer.rb"
  s.license = "MIT"

  s.files = Dir[
    "README.md",
    File.join("lib", "**", "*")
  ]

  s.require_path = "lib"

  s.add_development_dependency "m", "~> 1.0"
  s.add_development_dependency "byebug", "~> 11.0"
  s.add_development_dependency "pry", "~> 0.13"
  s.add_development_dependency "minitest", "~> 5.0"
end
