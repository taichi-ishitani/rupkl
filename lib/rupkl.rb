# frozen_string_literal: true

require 'base64'
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'
require 'singleton'
require 'stringio'
require 'parslet'
require 'regexp_parser'

require_relative 'rupkl/version'
require_relative 'rupkl/exception'
require_relative 'rupkl/pkl_object'
require_relative 'rupkl/node/context'
require_relative 'rupkl/node/node_common'
require_relative 'rupkl/node/value_common'
require_relative 'rupkl/node/type_common'
require_relative 'rupkl/node/member_finder'
require_relative 'rupkl/node/struct_common'
require_relative 'rupkl/node/reference_resolver'
require_relative 'rupkl/node/identifier'
require_relative 'rupkl/node/declared_type'
require_relative 'rupkl/node/member_reference'
require_relative 'rupkl/node/method_definition'
require_relative 'rupkl/node/method_call'
require_relative 'rupkl/node/amend_expression'
require_relative 'rupkl/node/if_expression'
require_relative 'rupkl/node/operation'
require_relative 'rupkl/node/this'
require_relative 'rupkl/node/any'
require_relative 'rupkl/node/null'
require_relative 'rupkl/node/boolean'
require_relative 'rupkl/node/number'
require_relative 'rupkl/node/string'
require_relative 'rupkl/node/regex'
require_relative 'rupkl/node/data_size'
require_relative 'rupkl/node/duration'
require_relative 'rupkl/node/pair'
require_relative 'rupkl/node/collection'
require_relative 'rupkl/node/map'
require_relative 'rupkl/node/intseq'
require_relative 'rupkl/node/dynamic'
require_relative 'rupkl/node/mapping'
require_relative 'rupkl/node/listing'
require_relative 'rupkl/node/object'
require_relative 'rupkl/node/pkl_module'
require_relative 'rupkl/node/base'
require_relative 'rupkl/parser'
require_relative 'rupkl/parser/misc'
require_relative 'rupkl/parser/literal'
require_relative 'rupkl/parser/identifier'
require_relative 'rupkl/parser/type'
require_relative 'rupkl/parser/expression'
require_relative 'rupkl/parser/method'
require_relative 'rupkl/parser/object'
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
      node = Parser.new.parse(pkl, filename:, root: :pkl_module)
      node.to_ruby(nil)
    end

    def load_file(filename)
      File.open(filename, 'r') { |io| load(io, filename:) }
    end
  end
end
