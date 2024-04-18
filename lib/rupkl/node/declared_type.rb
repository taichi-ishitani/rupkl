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

      def create(scopes, bodies, position, evaluator)
        klass = find_class(scopes, type)
        check_class(klass)
        create_object(klass, scopes, bodies, position, evaluator)
      end

      private

      def find_class(scopes, type)
        [Base.instance, *scopes].reverse_each do |scope|
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

      def create_object(klass, scopes, bodies, position, evaluator)
        klass.new(bodies.first.copy, position)
          .tap { |o| o.__send__(evaluator, scopes) }
          .tap do |o|
            bodies[1..].each do |b|
              o.merge!(b.__send__(evaluator, [*scopes, o]))
            end
          end
      end
    end
  end
end
