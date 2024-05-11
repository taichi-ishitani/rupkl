# frozen_string_literal: true

module RuPkl
  module Node
    class MethodParam
      include NodeCommon

      def initialize(parent, name, position)
        super
        @name = name
      end

      attr_reader :name
    end

    class MethodDefinition
      include NodeCommon

      def initialize(parent, name, params, body, position)
        super(parent, name, *params, body, position)
        @name = name
        @params = params
        @body = body
      end

      attr_reader :name
      attr_reader :params
      attr_reader :body
    end
  end
end
