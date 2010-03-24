module Authlogic
  module ActsAsAuthentic
    # Magic columns are like ActiveRecord's created_at and updated_at columns. They are "magically" maintained for
    # you. Authlogic has the same thing, but these are maintained on the session side. Please see Authlogic::Session::MagicColumns
    # for more details. This module merely adds validations for the magic columns if they exist.
    module MagicColumns
      def self.included(klass)
        klass.class_eval do
          add_acts_as_authentic_module(Methods)
        end
      end
      
      # Methods relating to the magic columns
      module Methods
        def self.included(klass)
          klass.class_eval do
            include Authlogic::Orm::ActsAsAuthentic::MagicColumns
          end
        end
      end
    end
  end
end
