# frozen_string_literal: true

module RuPkl
  module Node
    module PropertyEvaluator
      private

      def evaluate_property(value, objects, scopes)
        value&.evaluate(scopes) || evaluate_objects(objects, scopes)
      end

      def property_to_ruby(value, objects, scopes)
        if value
          value.to_ruby(scopes)
        else
          evaluate_objects(objects, scopes).to_ruby(nil)
        end
      end

      def property_to_pkl_string(value, objects, scopes)
        if value
          value.to_pkl_string(scopes)
        else
          evaluate_objects(objects, scopes).to_pkl_string(nil)
        end
      end

      def evaluate_objects(objects, scopes)
        objects
          .map { _1.evaluate(scopes) }
          .inject { |r, o| r.merge!(o) }
      end
    end

    class ObjectProperty
      include PropertyEvaluator

      def initialize(name, value, objects, position)
        @name = name
        @value = value
        @objects = objects
        @position = position
      end

      attr_reader :name
      attr_reader :value
      attr_reader :objects
      attr_reader :position

      def evaluate(scopes)
        v = evaluate_property(value, objects, scopes)
        self.class.new(name, v, nil, position)
      end

      def to_ruby(scopes)
        [name.id, property_to_ruby(value, objects, scopes)]
      end

      def to_pkl_string(scopes)
        v = property_to_pkl_string(value, objects, scopes)
        if v.start_with?('{')
          "#{name.id} #{v}"
        else
          "#{name.id} = #{v}"
        end
      end

      def ==(other)
        name.id == other.name.id && value == other.value
      end
    end

    class ObjectEntry
      include PropertyEvaluator

      def initialize(key, value, objects, position)
        @key = key
        @value = value
        @objects = objects
        @position = position
      end

      attr_reader :key
      attr_reader :value
      attr_reader :objects
      attr_reader :position

      def evaluate(scopes)
        k = key.evaluate(scopes)
        v = evaluate_property(value, objects, scopes)
        self.class.new(k, v, nil, position)
      end

      def to_ruby(scopes)
        k = key.to_ruby(scopes)
        v = property_to_ruby(value, objects, scopes)
        [k, v]
      end

      def to_pkl_string(scopes)
        k = key.to_pkl_string(scopes)
        v = property_to_pkl_string(value, objects, scopes)
        if v.start_with?('{')
          "[#{k}] #{v}"
        else
          "[#{k}] = #{v}"
        end
      end

      def ==(other)
        key == other.key && value == other.value
      end
    end

    class UnresolvedObject
      def initialize(members, position)
        @members = members
        @position = position
      end

      attr_reader :members
      attr_reader :position

      def evaluate(scopes)
        Dynamic.new(members, scopes, position)
      end

      def to_ruby(scopes)
        evaluate(scopes).to_ruby(nil)
      end

      def to_string(scopes)
        evaluate(scopes).to_string(nil)
      end

      def to_pkl_string(scopes)
        evaluate(scopes).to_pkl_string(nil)
      end
    end
  end
end
