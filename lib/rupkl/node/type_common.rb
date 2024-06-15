# frozen_string_literal: true

module RuPkl
  module Node
    module TypeCommon
      include NodeCommon

      def check_type(value, context, position)
        klass = value.class
        return if match_type?(klass, context)

        message =
          "expected type '#{self}', but got type '#{klass.class_name}'"
        raise EvaluationError.new(message, position)
      end

      private

      def find_type(type, context)
        exec_on(context) do |c|
          [Base.instance, *c&.objects]
            .reverse_each do |scope|
              next unless scope.respond_to?(:pkl_classes)

              klass = scope.pkl_classes&.fetch(type.last.id, nil)
              return klass if klass
            end

          raise EvaluationError.new("cannot find type '#{type.last.id}'", position)
        end
      end
    end
  end
end
