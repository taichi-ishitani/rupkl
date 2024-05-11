# frozen_string_literal: true

module RuPkl
  module Node
    class String < Any
      include ValueCommon

      uninstantiable_class

      def initialize(parent, value, portions, position)
        super(parent, value, position)
        @portions = portions
        portions&.each do |portion|
          portion.is_a?(NodeCommon) && add_child(portion)
        end
      end

      attr_reader :portions

      def evaluate(context = nil)
        @value ||= evaluate_portions(context)
        self
      end

      def to_pkl_string(context = nil)
        s = to_ruby(context)
        if invalid_string?(s)
          s
        else
          "\"#{escape(s)}\""
        end
      end

      def copy(parent = nil)
        copied_portions =
          portions&.map do |portion|
            portion.is_a?(NodeCommon) && portion.copy || portion
          end
        self.class.new(parent, nil, copied_portions, position)
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

        self.class.new(parent, value[index], nil, position)
      end

      private

      def evaluate_portions(context)
        evaluated_portions =
          portions&.map do |portion|
            evaluate_portion(portion, context)
              .tap { |s| return s if invalid_string?(s) }
          end
        evaluated_portions&.join || ''
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
