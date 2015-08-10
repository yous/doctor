require 'yard'

module Doctor
  # Support class for YARD documentation.
  module YARD
    # Setup proxy for testing.
    # @return [void]
    def self.setup
      ::YARD::CLI::Yardoc.run
      ::YARD::Registry.load

      traverse_node(::YARD::Registry.root, Object)
    end

    def self.traverse_node(node, context)
      node.children.each do |child|
        case child.type
        when :class, :module
          object = context.const_get(child.name)
          traverse_node(child, object)
        when :method
          proxy_method(child, context)
        when :constant, :classvariable
          next
        else
          fail NotImplementedError, "unknown type: #{child.type}"
        end
      end
    end
    private_class_method :traverse_node

    def self.proxy_method(method_obj, context)
      return if method_obj.name == :initialize
      tags = method_obj.tags.map do |tag|
        { tag_name: tag.tag_name, types: tag.types }
      end
      new_method_name = proxy_method_name(method_obj.name)

      class_eval_str = <<-EOF
        singleton_class.send(:alias_method,
                             :#{new_method_name}, :#{method_obj.name})

        define_singleton_method(:#{method_obj.name}) do |*args, &block|
          ::Doctor::Proxy::YARD.new(self, #{tags})
            .__send__(:#{new_method_name}, *args, &block)
        end
      EOF

      instance_eval_str = <<-EOF
        alias_method :#{new_method_name}, :#{method_obj.name}

        define_method(:#{method_obj.name}) do |*args, &block|
          ::Doctor::Proxy::YARD.new(self, #{tags})
            .__send__(:#{new_method_name}, *args, &block)
        end
      EOF

      if method_obj.scope == :class
        if context.is_a?(Module)
          context.class_eval(class_eval_str)
        elsif context.is_a?(Class)
          context.class_eval(class_eval_str)
        else
          fail NotImplementedError, "unknown context: #{context.class}"
        end
      elsif method_obj.scope == :instance
        context.class_eval(instance_eval_str)
      else
        fail NotImplementedError, "unknown scope: #{method_obj.scope}"
      end
    end
    private_class_method :proxy_method

    def self.proxy_method_name(method_name)
      method_name = method_name.to_s
      if method_name.end_with?('?') || method_name.end_with?('!')
        "#{method_name[0...-1]}_without_doctor#{method_name[-1]}"
      else
        "#{method_name}_without_doctor"
      end
    end
    private_class_method :proxy_method_name
  end
end
