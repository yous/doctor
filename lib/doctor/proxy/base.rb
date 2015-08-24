module Doctor
  module Proxy
    # Skeleton class for proxy.
    class Base < BasicObject
      def initialize(target, old_method, tags)
        @target = target
        @old_method = old_method
        @tags = tags
      end

      if ::RUBY_VERSION.to_f > 1.8
        def respond_to_missing?(method_name, include_private = false)
          super || @target.respond_to?(method_name, include_private)
        end
      else
        def respond_to?(method_name, include_private = false)
          super || @target.respond_to?(method_name, include_private)
        end
      end

      def method_missing(method_name, *args, &block)
        ::Kernel.fail method_name.to_s unless @old_method.name == method_name
        check_parameter_type(@old_method, *args, &block)
        value = @old_method.call(*args, &block)
        check_return_type(@old_method, value)
      end

      private

      def check_parameter_type(_method_name, *_args, &_block)
        ::Kernel.fail ::NotImplementedError,
                      'override #check_parameter_type in a subclass'
      end

      def check_return_type(_method_name, _value)
        ::Kernel.fail ::NotImplementedError,
                      'override #check_return_type in a subclass'
      end
    end
  end
end
