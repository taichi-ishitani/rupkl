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
      end

      abstract_class
      uninstantiable_class
    end
  end
end
