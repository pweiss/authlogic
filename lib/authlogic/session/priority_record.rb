module Authlogic
  module Session
    # The point of this module is to avoid the StaleObjectError raised when lock_version is implemented in ActiveRecord.
    # We accomplish this by using a "priority record". Meaning this record is used if possible, it gets priority.
    # This way we don't save a record behind the scenes thus making an object being used stale.
    module PriorityRecord
      def self.included(klass)
        klass.class_eval do
          attr_accessor :priority_record
        end
      end
      
      # Setting priority record if it is passed. The only way it can be passed is through an array:
      #
      #   session.credentials = [real_user_object, priority_user_object]
      include Authlogic::Orm::Session::PriorityRecord     

      private
        def attempted_record=(value)
          value = priority_record if value == priority_record
          super
        end
        
        def save_record(alternate_record = nil)
          r = alternate_record || record
          super if r != priority_record
        end
    end
  end
end
