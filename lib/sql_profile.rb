$:.unshift File.dirname(__FILE__)

module SqlProfile

  mattr_accessor :controller
  mattr_accessor :data
  mattr_accessor :segment
  
  def self.append_features(klass)
    super

    klass.class_eval do
      unless method_defined?(:log_info_without_profile)
        alias_method :log_info_without_profile, :log_info
        alias_method :log_info, :log_info_with_profile
      end
    end
  end

  def self.around_filter(controller, segment=nil)
    SqlProfile.controller = controller
    SqlProfile.segment    = controller
    yield
  ensure
    SqlProfile.controller = nil
    SqlProfile.segment    = nil

    Rails.logger.info "!"*50
    Rails.logger.info SqlProfile.data.pretty_inspect
  end
  
  def log_info_with_profile(sql, name, runtime)
    log_info_without_profile(sql, name, runtime)

    return unless controller = SqlProfile.controller    
    return unless @logger and @logger.debug?

    return if / Columns$/     =~ name
    return if /Mysql::Error/  =~ sql
    return if /^EXPLAIN/      =~ sql

    results  = ActiveRecord::Base.connection.execute("EXPLAIN #{sql}")
    path     = controller.request.path
    explains = [] 

    while explain = results.fetch_hash
      explain.delete('rows')
      explains << explain
    end
    
    SqlProfile.data       ||= {}
    SqlProfile.data[path] ||= []
    SqlProfile.data[path]  << explains
  end
end