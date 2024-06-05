# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:method_header) do
        kw_function.as(:kw_function) >> ws >>
          id.as(:name) >> ws? >> method_params.as(:params) >>
          (ws? >> type_annotation.as(:type)).maybe
      end

      rule(:method_params) do
        bracketed(list(method_param).maybe, '(', ')').as(:method_params)
      end

      rule(:method_param) do
        (
          id.as(:name) >> (ws? >> type_annotation.as(:type)).maybe
        ).as(:method_param)
      end
    end

    define_transform do
      rule(method_params: subtree(:params)) do
        params == '' ? nil : Array(params)
      end

      rule(
        method_param: { name: simple(:name) }
      ) do
        Node::MethodParam.new(nil, name, nil, name.position)
      end

      rule(
        method_param: { name: simple(:name), type: simple(:type) }
      ) do
        Node::MethodParam.new(nil, name, type, name.position)
      end
    end
  end
end
