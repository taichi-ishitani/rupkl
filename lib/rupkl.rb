# frozen_string_literal: true

require 'stringio'
require 'parslet'
require 'facets/module/basename'

require_relative 'rupkl/version'
require_relative 'rupkl/exception'
require_relative 'rupkl/pkl_object'
require_relative 'rupkl/node/value_common'
require_relative 'rupkl/node/struct_common'
require_relative 'rupkl/node/boolean'
require_relative 'rupkl/node/number'
require_relative 'rupkl/node/string'
require_relative 'rupkl/node/identifier'
require_relative 'rupkl/node/expression'
require_relative 'rupkl/node/pkl_object'
require_relative 'rupkl/node/pkl_class'
require_relative 'rupkl/node/pkl_module'
require_relative 'rupkl/parser'
require_relative 'rupkl/parser/misc'
require_relative 'rupkl/parser/literal'
require_relative 'rupkl/parser/identifier'
require_relative 'rupkl/parser/expression'
require_relative 'rupkl/parser/pkl_object'
require_relative 'rupkl/parser/pkl_class'
require_relative 'rupkl/parser/pkl_module'

module RuPkl
  class << self
    def load(string_or_io, filename: nil)
      pkl =
        if string_or_io.respond_to?(:read)
          string_or_io.read
        else
          string_or_io
        end
      node = Parser.new.parse(pkl, filename: filename, root: :pkl_module)
      node.to_ruby(nil)
    end

    def load_file(filename)
      File.open(filename, 'r') { |io| load(io, filename: filename) }
    end
  end
end
