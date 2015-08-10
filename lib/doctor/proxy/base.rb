module Doctor
  module Proxy
    # Skeleton class for proxy.
    class Base
      def initialize(target, tags)
        @target = target
        @tags = tags
      end

      if RUBY_VERSION.to_f > 1.8
        def respond_to_missing?(method_name, include_private = false)
          super || @target.respond_to?(method_name, include_private)
        end
      else
        def respond_to?(method_name, include_private = false)
          super || @target.respond_to?(method_name, include_private)
        end
      end

      def method_missing(method_name, *args, &block)
        check_parameter_type(method_name, *args, &block)
        value = @target.__send__(method_name, *args, &block)
        check_return_type(method_name, value)
      end

      private

      def check_parameter_type(_method_name, *_args, &_block)
        fail NotImplementedError, 'override #check_parameter_type in a subclass'
      end

      def check_return_type(_method_name, _value)
        fail NotImplementedError, 'override #check_return_type in a subclass'
      end
    end
  end
end
