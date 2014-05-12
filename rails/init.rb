require File.expand_path('../../lib/sql_profile', __FILE__)

::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, SqlProfile)