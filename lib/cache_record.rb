require 'cache_record/by_finder'
require 'cache_record/instance'

ActiveRecord::Base.send :include, CacheRecord::ByFinder
ActiveRecord::Base.send :include, CacheRecord::Instance