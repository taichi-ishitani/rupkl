[![Gem Version](https://badge.fury.io/rb/rupkl.svg)](https://badge.fury.io/rb/rupkl)
[![CI](https://github.com/taichi-ishitani/rupkl/actions/workflows/ci.yml/badge.svg)](https://github.com/taichi-ishitani/rupkl/actions/workflows/ci.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/ee9795f03af99994d139/maintainability)](https://codeclimate.com/github/taichi-ishitani/rupkl/maintainability)
[![codecov](https://codecov.io/github/taichi-ishitani/rupkl/graph/badge.svg?token=CrcaXQ9FjI)](https://codecov.io/github/taichi-ishitani/rupkl)

# RuPkl

A [Pkl](https://pkl-lang.org) parser for Ruby.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rupkl

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rupkl

## Usage

You can use the methods below to load a Pkl code into a Ruby structure:

* `RuPkl.load`
    * Load the given Pkl code into a Ruby structure
* `RuPkl.load_file`
    * Load a Pkl code read from the given file path into a Ruby structure

```ruby
require 'rupkl'

pkl = <<~'PKL'
  // From:
  // https://pkl-lang.org/main/current/language-tutorial/01_basic_config.html
  name = "Pkl: Configure your Systems in New Ways"
  attendants = 100
  isInteractive = true
  amountLearned = 13.37
PKL

RuPkl.load(pkl)
# =>
# {:name=>"Pkl:Configure your Systems in New Ways",
#  :attendants=>100,
#  :isInteractive=>true,
#  :amountLearned=>13.37}

File.open('sample.pkl', 'w') do |f|
  f.write(<<~'PKL')
    // From:
    // https://pkl-lang.org/main/current/language-tutorial/01_basic_config.html
    bird {
      name = "Common wood pigeon"
      diet = "Seeds"
      taxonomy {
        species = "Columba palumbus"
      }
    }

    exampleObjectWithJustIntElements {
      100
      42
    }

    exampleObjectWithMixedElements {
      "Bird Breeder Conference"
      (2000 + 23)
      exampleObjectWithJustIntElements
    }

    pigeonShelter {
      ["bird"] {
        name = "Common wood pigeon"
        diet = "Seeds"
        taxonomy {
          species = "Columba palumbus"
        }
      }
      ["address"] = "355 Bird St."
    }

    birdCount {
      [pigeonShelter] = 42
    }
  PKL
end

RuPkl.load_file('sample.pkl')
# =>
# {:bird=>{:name=>"Common wood pigeon", :diet=>"Seeds", :taxonomy=>{:species=>"Columba palumbus"}},
#  :exampleObjectWithJustIntElements=>[100, 42],
#  :exampleObjectWithMixedElements=>["Bird Breeder Conference", 2023, [100, 42]],
#  :pigeonShelter=>
#   {"bird"=>{:name=>"Common wood pigeon", :diet=>"Seeds", :taxonomy=>{:species=>"Columba palumbus"}},
#    "address"=>"355 Bird St."},
#  :birdCount=>
#   {{"bird"=>{:name=>"Common wood pigeon", :diet=>"Seeds", :taxonomy=>{:species=>"Columba palumbus"}},
#     "address"=>"355 Bird St."}=>42}}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/taichi-ishitani/rupkl.

* [Issue Tracker](https://github.com/taichi-ishitani/rupkl/issues/new/choose)
* [Discussion](https://github.com/taichi-ishitani/rupkl/discussions/new/choose)
* [Pull Request](https://github.com/taichi-ishitani/rupkl/pulls)

## Notice

Pkl code snippets used for RSpec examples are originaly from:

* https://pkl-lang.org/main/current/language-tutorial/index.html
* https://github.com/apple/pkl

## Copyright & License

Copyright &copy; 2024 Taichi Ishitani.
RuPkl is licensed under the terms of the [MIT License](https://opensource.org/licenses/MIT), see [LICENSE.txt](LICENSE.txt) for further details.

## Code of Conduct

Everyone interacting in the RuPkl project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/taichi-ishitani/rupkl/blob/master/CODE_OF_CONDUCT.md).
