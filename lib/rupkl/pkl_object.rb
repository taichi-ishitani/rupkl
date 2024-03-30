# frozen_string_literal: true

module RuPkl
  class PklObject
    include Enumerable

    def initialize(properties, elements, entries)
      @properties = properties
      @elements = elements
      @entries = entries
      define_property_accessors
    end

    def members
      @members ||=
        [
          *properties.to_a,
          *elements.map.with_index { |e, i| [i, e] },
          *entries.to_a
        ]
    end

    def properties
      @properties ||= {}
    end

    def elements
      @elements ||= []
    end

    def entries
      @entries ||= {}
    end

    {
      members: :each, properties: :each_property,
      elements: :each_element, entries: :each_entry
    }.each do |accessor, method|
      class_eval(<<~M, __FILE__, __LINE__ + 1)
        # def each(&block)
        #   if block_given?
        #     members.each(&block)
        #   else
        #     members.each
        #   end
        # end
        def #{method}(&block)
          if block_given?
            #{accessor}.each(&block)
          else
            #{accessor}.each
          end
        end
      M
    end

    private

    def define_property_accessors
      return unless @properties

      properties.each_key do |name|
        singleton_class.class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def foo
          #   properties[__method__]
          # end
          def #{name}
            properties[__method__]
          end
        M
      end
    end
  end
end
