# frozen_string_literal: true

module RuPkl
  class PklObject
    include Enumerable

    def initialize(properties, entries, elements)
      @properties = properties
      @entries = entries
      @elements = elements
      define_property_accessors
    end

    def [](key)
      if properties.key?(key)
        properties[key]
      elsif key.is_a?(Integer) && key < elements.size
        elements[key]
      else
        entries[key]
      end
    end

    def members
      @members ||=
        [
          *properties.to_a,
          *entries.to_a,
          *elements
        ]
    end

    def properties
      @properties ||= {}
    end

    def entries
      @entries ||= {}
    end

    def elements
      @elements ||= []
    end

    {
      members: :each, properties: :each_property,
      entries: :each_entry, elements: :each_element
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

    def to_s
      if element_only?
        elements.to_s
      else
        "{#{mixed_to_s}}"
      end
    end

    def inspect
      to_s
    end

    def pretty_print(pp)
      if element_only?
        pp.pp(elements)
      else
        pp_mixed(pp)
      end
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

    def element_only?
      properties.empty? && entries.empty? && !elements.empty?
    end

    def mixed_to_s
      [properties, entries, elements]
        .reject(&:empty?)
        .map { _1.to_s[1..-2] }
        .join(', ')
    end

    def pp_mixed(pp)
      pp.group(1, '{', '}') do
        pp.seplist(pp_members, nil, :each) do |(member, type)|
          pp_mixed_body(pp, type, member)
        end
      end
    end

    def pp_members
      [
        *properties.to_a.product([:property]),
        *entries.to_a.product([:entry]),
        *elements.product([:element])
      ]
    end

    def pp_mixed_body(pp, type, member)
      if type in :property | :entry
        pp_hash_pair(pp, *member)
      else
        pp.pp(member)
      end
    end

    def pp_hash_pair(pp, key, value)
      pp.group do
        pp.pp(key)
        pp.text('=>')
        pp.group(1) do
          pp.breakable('')
          pp.pp(value)
        end
      end
    end
  end
end
