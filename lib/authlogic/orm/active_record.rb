module Authlogic
  module Orm
    module ModelExtends
      module ClassMethods
      end
      module InstanceMethods
      end
    end

    module ActsAsAuthentic
      module LoggedInStatus
        extend ActiveSupport::Concern

        included do
          named_scope :logged_in, lambda { { :conditions => ["last_request_at > ?", logged_in_timeout.seconds.ago] } }
          named_scope :logged_out, lambda { { :conditions => ["last_request_at is NULL or last_request_at <= ?", logged_in_timeout.seconds.ago] } }
        end
      end

      module Login
        private

        def find_with_case(field, value, sensitivity = true)
          if sensitivity
            send("find_by_#{field}", value)
          else
            first(:conditions => ["LOWER(#{quoted_table_name}.#{field}) = ?", value.mb_chars.downcase])
          end
        end
      end

      module MagicColumns
        extend ActiveSupport::Concern

        included do
          validates_numericality_of :login_count, :only_integer => :true, :greater_than_or_equal_to => 0, :allow_nil => true if column_names.include?("login_count")
          validates_numericality_of :failed_login_count, :only_integer => :true, :greater_than_or_equal_to => 0, :allow_nil => true if column_names.include?("failed_login_count")
        end
      end

      module PerishableToken
        def find_using_perishable_token(token, age = self.perishable_token_valid_for)
          return if token.blank?
          age = age.to_i
          
          conditions_sql = "perishable_token = ?"
          conditions_subs = [token]
          
          if column_names.include?("updated_at") && age > 0
            conditions_sql += " and updated_at > ?"
            conditions_subs << age.seconds.ago
          end
          
          find(:first, :conditions => [conditions_sql, *conditions_subs])
        end

        def find_using_perishable_token!(token, age = perishable_token_valid_for)
          find_using_perishable_token(token, age) || raise(ActiveRecord::RecordNotFound)
        end
      end
     
      module SessionMaintenance
        def save_without_session_maintenance(*args)
          self.skip_session_maintenance = true
          result = save(*args)
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
          self.priority_record = values[1] if values[1].class < ::ActiveRecord::Base
        end
      end

      module UnauthorizedRecord
        def credentials=(value)
          super
          values = value.is_a?(Array) ? value : [value]
          self.unauthorized_record = values.first if values.first.class < ::ActiveRecord::Base
        end
      end

      module Validation
        class Errors < (defined?(::ActiveModel) ? ::ActiveModel::Errors : ::ActiveRecord::Errors)
          unless defined?(::ActiveModel)
            def [](key)
              value = super
              value.is_a?(Array) ? value : [value].compact
            end
          end
        end
      end
      
    end
  end
end

