# frozen_string_literal: true

module RuPkl
  module Node
    class String
      include ValueCommon

      def initialize(value, portions, position)
        super(value, position)
        @portions = portions
      end

      attr_reader :portions

      def evaluate(scopes)
        s = value || evaluate_portions(scopes) || ''
        self.class.new(s, nil, position)
      end

      def to_pkl_string(scopes)
        super(scopes)
          .then { |s| escape(s) }
          .then { |s| "\"#{s}\"" }
      end

      def undefined_operator?(operator)
        [:[], :==, :'!=', :+].none?(operator)
      end

      def invalid_key_operand?(key)
        !key.is_a?(Integer)
      end

      def find_by_key(key)
        index = key.value
        return nil unless (0...value.length).include?(index)

        self.class.new(value[index], nil, portions)
      end

      private

      def evaluate_portions(scopes)
        portions
          &.map { evaluate_portion(scopes, _1) }
          &.join
      end

      def evaluate_portion(scopes, portion)
        if portion.respond_to?(:to_string)
          portion.to_string(scopes)
        else
          portion
        end
      end

      def escape(string)
        replace = {
          "\t" => '\t', "\n" => '\n', "\r" => '\r',
          '"' => '\"', '\\' => '\\\\'
        }
        string.gsub(/([\t\n\r"\\])/) { replace[_1] }
      end
    end
  end
end
