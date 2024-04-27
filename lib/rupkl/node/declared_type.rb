# frozen_string_literal: true

module RuPkl
  module Node
    class DeclaredType
      include NodeCommon

      def initialize(type, position)
        super(*type, position)
        @type = type
      end

      attr_reader :type

      def create(bodies, position, context)
        klass = find_class(type, context)
        check_class(klass)
        create_object(klass, bodies, position, context)
      end

      private

      def find_class(type, context)
        [Base.instance, *context&.objects].reverse_each do |scope|
          next unless scope.respond_to?(:classes)

          klass = scope.classes&.fetch(type.last.id, nil)
          return klass if klass
        end

        nil
      end

      def check_class(klass)
        message =
          if klass.nil?
            "cannot find type '#{type.last.id}'"
          elsif klass.abstract?
            "cannot instantiate abstract class '#{klass.class_name}'"
          elsif !klass.instantiable?
            "cannot instantiate class '#{klass.class_name}'"
          else
            return
          end
        raise EvaluationError.new(message, position)
      end

      def create_object(klass, bodies, position, context)
        klass.new(bodies.first.copy, position)
          .tap { |o| o.evaluate_lazily(context) }
          .tap do |o|
            push_object(context, o) do |c|
              o.merge!(*bodies[1..].each { |b| b.evaluate_lazily(c) })
            end
          end
      end
    end
  end
end
