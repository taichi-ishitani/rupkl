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

    def to_s
      "{#{members_to_s}}"
    end

    def inspect
      to_s
    end

    def pretty_print(pp)
      pp.group(1, '{', '}') { pp_body(pp) }
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

    def members_to_s
      [properties, entries, elements]
        .reject(&:empty?)
        .map { _1.to_s[1..-2] }
        .join(', ')
    end

    def pp_body(pp)
      pp.seplist([*properties, *entries, *elements], nil, :each) do |member|
        case member
        when Array then pp_hash_member(pp, *member)
        else pp.pp(member)
        end
      end
    end

    def pp_hash_member(pp, key, value)
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
