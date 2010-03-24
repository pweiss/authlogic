module Authlogic
  module Orm
    module ModelExtends
      module ClassMethods
        def primary_key
          "_id"
        end
        def default_timezone
          :local
        end
      end
      module InstanceMethods
        extend ActiveSupport::Concern

        included do
          send(:extend, Authlogic::Session::Scopes::ClassMethods)
        end
        def readonly?
          false
        end
      end
    end
    
    module ActsAsAuthentic
      module LoggedInStatus
        extend ActiveSupport::Concern
        
        included do
          send(:extend, ClassMethods)
        end
        
        module ClassMethods
          def logged_in
            all(:conditions => {"last_request_at" => { '$gt' => Time.to_mongo(logged_in_timeout.seconds.ago) }} )
          end

          def logged_out
            all(:conditions => {"last_request_at" => 'null'})
            +
            all(:conditions => {"last_request_at" => { '$lt' => Time.to_mongo(logged_in_timeout.seconds.ago) }} )
          end
        end
      end

      module Login
        private

        def find_with_case(field, value, sensitivity = true)
          if sensitivity
            send("find_by_#{field}", value)
          else
            first(:conditions => {"#{field.to_s}" => value.mb_chars.to_s.downcase} )
          end
        end
      end

      module MagicColumns
        extend ActiveSupport::Concern

        included do
          #validates_numericality_of :login_count, :only_integer => :true, :greater_than_or_equal_to => 0, :allow_nil => true if column_names.include?("login_count")
          #validates_numericality_of :failed_login_count, :only_integer => :true, :greater_than_or_equal_to => 0, :allow_nil => true if column_names.include?("failed_login_count")
        end
      end

      module PerishableToken
        def find_using_perishable_token(token, age = self.perishable_token_valid_for)
          return if token.blank?
          age = age.to_i
          
          if column_names.include?("updated_at") && age > 0
            first(:conditions => {"perishable_token" => token, "updated_at" => {'$gt' => age.seconds.ago}} )
          else
            first(:conditions => {"perishable_token" => token} )
          end
        end

        def find_using_perishable_token!(token, age = perishable_token_valid_for)
          find_using_perishable_token(token, age) || raise(MongoMapper::DocumentNotFound)
        end
      end

      module SessionMaintenance
        def save_without_session_maintenance(args)
          self.skip_session_maintenance = true
          result = save(:validate => args)
          self.skip_session_maintenance = false
          result
        end
      end
    end
    
    module Session
      module PriorityRecord
        def credentials=(value)
          super
          values = value.is_a?(Array) ? value : [value]
          self.priority_record = values[1] if values[1].class < ::MongoMapper::Document
        end
      end

      module UnauthorizedRecord
        def credentials=(value)
          super
          values = value.is_a?(Array) ? value : [value]
          self.unauthorized_record = values.first if values.first.class < ::MongoMapper::Document
        end
      end
      
      module Validation
        class Errors < ::Validatable::Errors
          def initialize(value)
          end
          def [](key)
            value = super
            value.is_a?(Array) ? value : [value].compact
          end
        end
      end
    end

  end
end

