module CacheRecord
  module Instance
    def self.included(target)
      target.send( :extend, ClassMethods )
      target.send(:include, InstanceMethods )
    end

    module ClassMethods

      def cache_record_instance(options = {})
        (class << self; self; end).module_eval do
          define_method :instance_with_cache_record do
            Rails.cache.fetch("#{self.table_name}/instance") do
              instance_without_cache_record
            end
          end

          def update_all_with_cached_record_invalidation(*args)
            Rails.cache.delete("#{self.table_name}/instance")
            update_all_without_cached_record_invalidation(*args)
          end

          def delete_all_with_cached_record_invalidation(*args)
            Rails.cache.delete("#{self.table_name}/instance")
            delete_all_without_cached_record_invalidation(*args)
          end

          if method_defined?(:instance)
            alias_method_chain :instance, :cache_record
            alias_method_chain :update_all, :cached_record_invalidation
            alias_method_chain :delete_all, :cached_record_invalidation
          else
            raise "'instance' definition not found. Define a class method 'instance' which will return the instance of the Singleton class."
          end
        end

        after_save    :invalidate_cached_record_instance
        after_destroy :invalidate_cached_record_instance
      end
    end

    module InstanceMethods

      def invalidate_cached_record_instance
        Rails.cache.delete("#{self.table_name}/instance")
      end
    end
  end
end
