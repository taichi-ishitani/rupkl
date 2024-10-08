# frozen_string_literal: true

module RuPkl
  module Node
    class Any
      include NodeCommon

      class << self
        def abstract?
          @abstract || false
        end

        def instantiable?
          !@uninstantiable
        end

        def class_name
          @class_name ||= to_s.split('::').last.to_sym
        end

        def builtin_property(name)
          @builtin_properties&.[](name.to_sym)
        end

        def buildin_method(name)
          @builtin_methods&.[](name.to_sym)
        end

        private

        def abstract_class
          @abstract = true
        end

        def uninstantiable_class
          @uninstantiable = true
        end

        def klass_name(name)
          @class_name = name
        end

        def define_builtin_property(name, &body)
          (@builtin_properties ||= {})[name] = body
        end

        def define_builtin_method(name, ...)
          (@builtin_methods ||= {})[name] = BuiltinMethodDefinition.new(name, ...)
        end
      end

      abstract_class
      uninstantiable_class

      def property(name)
        builtin_property(name)
      end

      def pkl_method(name)
        buildin_method(name)
      end

      def null?
        false
      end

      def class_name
        self.class.class_name
      end

      private

      def builtin_property(name)
        self.class.ancestors.each do |klass|
          next unless klass.respond_to?(:builtin_property)

          body = klass.builtin_property(name)
          return instance_exec(&body) if body
        end

        nil
      end

      def buildin_method(name)
        self.class.ancestors.each do |klass|
          next unless klass.respond_to?(:buildin_method)

          method = klass.buildin_method(name)
          return method if method
        end

        nil
      end

      def check_positive_number(number, position)
        return unless number.value.negative?

        m = "expected a positive number, but got '#{number.value}'"
        raise EvaluationError.new(m, position)
      end

      protected

      def execute_builtin_method(name, arguments, parent, position)
        buildin_method(name)
          .execute_method(self, arguments, parent, position)
      end
    end
  end
end
