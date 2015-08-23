require 'yard'

module Doctor
  module Proxy
    # Proxy class for YARD documentation.
    class YARD < Base
      private

      def check_parameter_type(meth, *args, &_block)
        param_tags = @tags.select { |tag| tag[:tag_name] == 'param' }
        return unless param_tags

        args.zip(param_tags).each do |arg, tag|
          break unless tag
          types = tag[:types]

          next if types.any? { |type| arg.is_a?(Object.const_get(type)) }

          fail ArgumentError,
               "#{@target} #{meth.name}: expected type: #{types}, got: #{arg}"
        end
      end

      def check_return_type(meth, value)
        return_tag = @tags.find { |tag| tag[:tag_name] == 'return' }
        return unless return_tag

        types = return_tag[:types]
        return if types.any? { |type| type == 'void' }
        return if types.any? { |type| value.is_a?(Object.const_get(type)) }

        fail ReturnTypeError,
             "#{@target} #{meth.name}: expected type: #{types}, got: #{value}"
      end
    end
  end
end
