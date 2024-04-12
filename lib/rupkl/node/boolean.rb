# frozen_string_literal: true

module RuPkl
  module Node
    class Boolean < Any
      include ValueCommon

      uninstantiable_class

      def undefined_operator?(operator)
        [:!, :==, :'!=', :'&&', :'||'].none?(operator)
      end

      def short_circuit?(operator)
        [operator, value] in [:'&&', false] | [:'||', true]
      end
    end
  end
end
