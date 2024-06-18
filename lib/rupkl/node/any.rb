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
          @class_name || basename.to_sym
        end

        def builtin_property(name)
          @builtin_properties&.[](name.id)
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
      end

      abstract_class
      uninstantiable_class

      def property(name)
        builtin_property(name)
      end

      private

      def builtin_property(name)
        self.class.ancestors.each do |klass|
          break if klass > Any
          next unless klass.respond_to?(:builtin_property)

          body = klass.builtin_property(name)
          return instance_exec(&body) if body
        end
      end
    end
  end
end
