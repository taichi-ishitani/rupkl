# frozen_string_literal: true

module RuPkl
  module Node
    class DeclaredType
      include NodeCommon

      def initialize(parent, type, position)
        super(parent, *type, position)
        @type = type
      end

      attr_reader :type

      def create(parent, bodies, position, context)
        klass = find_class(type, context)
        check_class(klass)
        create_object(parent, klass, bodies, position)
      end

      private

      def find_class(type, context)
        [Base.instance, *(context || current_context)&.objects]
          .reverse_each do |scope|
            next unless scope.respond_to?(:pkl_classes)

            klass = scope.pkl_classes&.fetch(type.last.id, nil)
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

      def create_object(parent, klass, bodies, position)
        klass.new(parent, bodies.first.copy, position)
          .tap(&:evaluate_lazily)
          .tap do |o|
            bodies[1..]
              .map { _1.copy(o).evaluate_lazily }
              .then { o.merge!(*_1) }
          end
      end
    end
  end
end
