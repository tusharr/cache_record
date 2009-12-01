module CacheRecord
  module ByFinder
    def self.included(target)
      target.send( :extend, ClassMethods )
      target.send(:cattr_accessor, :cache_record_attributes)
      target.send(:include, InstanceMethods )
    end

    module ClassMethods

      def cache_record_by(*attrs)
        self.cache_record_attributes ||= []
        self.cache_record_attributes += attrs
        attrs.each do |attr|
          (class << self; self; end).module_eval do

            define_method "find_by_#{attr}" do |arg|
              Rails.cache.fetch("#{self.table_name}/#{attr}/#{arg}") do
                super(arg)
              end
            end

          end
        end

        (class << self; self; end).module_eval do
          def update_all_with_cached_record_invalidation(*args)
            invalidate_complete_cache
            update_all_without_cached_record_invalidation(*args)
          end

          def delete_all_with_cached_record_invalidation(*args)
            invalidate_complete_cache
            delete_all_without_cached_record_invalidation(*args)
          end

          def invalidate_complete_cache
            self.all.each do |record|
              self.cache_record_attributes.each do |attribute|
                Rails.cache.delete "#{self.class.table_name}/#{attribute}/#{record.send(attribute)}"
              end
            end
          end

          alias_method_chain :update_all, :cached_record_invalidation
          alias_method_chain :delete_all, :cached_record_invalidation

        end


        after_save    :invalidate_cached_record
        after_destroy :invalidate_cached_record
      end
    end

    module InstanceMethods

      def invalidate_cached_record
        self.class.cache_record_attributes.each do |cached_attr|
          Rails.cache.delete "#{self.class.table_name}/#{attr}/#{arg}"
        end
      end

    end
  end
end