require 'yard'
require 'rubycheck'

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
          quickcheck_method(child, context)
        when :constant, :classvariable
          next
        else
          fail NotImplementedError, "unknown type: #{child.type}"
        end
      end
    end
    private_class_method :traverse_node

    def self.quickcheck_method(method_obj, context)
      tags = method_obj.tags.map do |tag|
        { tag_name: tag.tag_name, types: tag.types }
      end
      param_tags = tags.select { |tag| tag[:tag_name] == 'param' }

      return unless param_tags

      RubyCheck.class_eval(<<-EOF)
        define_singleton_method(:gen_params) do
          #{tags}.map do |tag|
            case tag[:types].sample
            when 'Boolean' then gen_bool
            when 'Float'   then gen_float
            when 'Integer' then gen_int
            when 'String'  then gen_str
            end
          end
        end
      EOF

      prop = lambda do |args|
        if method_obj.scope == :class
          context.__send__(method_obj.name, *args)
        elsif method_obj.scope == :instance
          if context.instance_of?(Module)
            new_class = Class.new do
              include context
            end
            new_class.new.__send__(method_obj.name, *args)
          else
            # Should be generalized with arguments for initialize.
            context.new.__send__(method_obj.name, *args)
          end
        end
      end

      RubyCheck.for_all(prop, [:gen_params])
      RubyCheck.class_eval do
        class << self
          remove_method :gen_params
        end
      end
    end
    private_class_method :quickcheck_method

    def self.proxy_method(method_obj, context)
      return if method_obj.name == :initialize
      tags = method_obj.tags.map do |tag|
        { tag_name: tag.tag_name, types: tag.types }
      end
      method_name = method_obj.name

      class_eval_str = <<-EOF
        old_method = singleton_method(:#{method_name})

        define_singleton_method(:#{method_name}) do |*args, &block|
          ::Doctor::Proxy::YARD.new(self, old_method, #{tags})
            .__send__(:#{method_name}, *args, &block)
        end
      EOF

      instance_eval_str = <<-EOF
        old_method = instance_method(:#{method_name})

        define_method(:#{method_name}) do |*args, &block|
          ::Doctor::Proxy::YARD.new(self, old_method.bind(self), #{tags})
            .__send__(:#{method_name}, *args, &block)
        end
      EOF

      if method_obj.scope == :class
        if context.instance_of?(Module)
          context.class_eval(class_eval_str)
        elsif context.instance_of?(Class)
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
  end
end
