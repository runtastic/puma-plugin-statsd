Gem::Specification.new do |spec|
  spec.name     = "puma-plugin-statsd"
  spec.version  = "1.0.2"
  spec.author   = "Gabriel Bustamante"
  spec.email    = "gabriel.bustamante@runtastic.com"

  spec.summary  = "Send puma metrics to statsd using the dogstatsd client via a background thread"
  spec.homepage = "https://github.com/runtastic/puma-plugin-statsd"
  spec.license  = "MIT"

  spec.files = Dir["lib/**/*.rb", "README.md", "CHANGELOG.md", "MIT-LICENSE"]

  spec.add_runtime_dependency "puma", ">= 3.12", "< 6"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "dogstatsd-ruby", "~> 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "rack"
end
