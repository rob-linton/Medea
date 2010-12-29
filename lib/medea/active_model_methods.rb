module Medea
  module ActiveModelMethods
    def to_model
      jason_key
    end

    def errors
      obj = Object.new
      def obj.[](key)         [] end
      def obj.full_messages() [] end
      obj
    end

    def persisted?
      jason_state == :stale
    end

    def valid?
      true
    end
  end
end