# frozen_string_literal: true

require_relative 'lib/rupkl/version'

Gem::Specification.new do |spec|
  spec.name = 'rupkl'
  spec.version = RuPkl::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['taichi730@gmail.com']

  spec.summary = 'Pkl parser for Ruby'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/taichi-ishitani/rupkl'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z lib *.md *.txt`.split("\x0")
  end
  spec.require_paths = ['lib']
end
