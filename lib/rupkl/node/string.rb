# frozen_string_literal: true

module RuPkl
  module Node
    class String < Any
      include ValueCommon

      uninstantiable_class

      def initialize(value, portions, position)
        super(value, position)
        @portions = portions
      end

      attr_reader :portions

      def evaluate(context)
        @value ||= (evaluate_portions(context) || '')
        self
      end

      def to_pkl_string(context)
        super
          .then { |s| escape(s) }
          .then { |s| "\"#{s}\"" }
      end

      def copy
        self.class.new(nil, portions, position)
      end

      def undefined_operator?(operator)
        [:[], :==, :'!=', :+].none?(operator)
      end

      def invalid_key_operand?(key)
        !key.is_a?(Int)
      end

      def find_by_key(key)
        index = key.value
        return nil unless (0...value.length).include?(index)

        self.class.new(value[index], nil, portions)
      end

      private

      def evaluate_portions(context)
        portions
          &.map { evaluate_portion(_1, context) }
          &.join
      end

      def evaluate_portion(portion, context)
        if portion.respond_to?(:to_string)
          portion.to_string(context)
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
