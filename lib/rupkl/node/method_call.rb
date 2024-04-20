# frozen_string_literal: true

module RuPkl
  module Node
    class MethodCall
      include NodeCommon

      def initialize(receiver, method_name, arguments, position)
        super(receiver, method_name, *arguments, position)
        @receiver = receiver
        @method_name = method_name
        @arguments = arguments
      end

      attr_reader :receiver
      attr_reader :method_name
      attr_reader :arguments
    end
  end
end
