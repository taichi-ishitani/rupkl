# frozen_string_literal: true

module RuPkl
  module Node
    class Number
      include ValueCommon
      include Operatable

      def evaluate(_scopes)
        self
      end

      private

      def undefined_operator?(operator)
        [:!, :'&&', :'||'].include?(operator)
      end

      def invalid_operand?(operand)
        !(operand.class <=> Number)
      end

      def coerce(operator, l_operand, r_operand)
        case [operator, l_operand, r_operand]
        in [:'~/', l, r]
          [:/, l.value.to_i, r.value.to_i]
        in [op, Integer => l, Integer => r] unless op == :/
          [op, l.value.to_i, r.value.to_i]
        in [op, l, r]
          [op, l.value.to_f, r.value.to_f]
        end
      end
    end

    class Integer < Number
    end

    class Float < Number
    end
  end
end
