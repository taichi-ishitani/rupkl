# frozen_string_literal: true

module RuPkl
  module Node
    class Boolean
      include ValueCommon
      include Operatable

      def evaluate(_scopes)
        self
      end

      private

      def undefined_operator?(operator)
        [:!, :==, :'!=', :'&&', :'||'].none?(operator)
      end

      def short_circuit?(operator)
        case [operator, value]
        in [:'&&', false] | [:'||', true] then true
        else false
        end
      end

      def coerce(operator, l_operand, r_operand)
        case [operator, l_operand, r_operand]
        in [:'&&' => op, l, r] then [:&, l.value, r.value]
        in [:'||' => op, l, r] then [:|, l.value, r.value]
        in [op, l, r] then [op, l.value, r.value]
        end
      end
    end
  end
end
