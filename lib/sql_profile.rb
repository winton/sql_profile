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
    self.controller = controller
    self.segment    = segment
    yield
  ensure
    self.controller = nil
    self.segment    = nil

    Rails.logger.info "!"*50
    Rails.logger.info self.data.pretty_inspect
  end

  def add_explains(explains)
    path     = SqlProfile.controller.request.path
    segment  = SqlProfile.segment
    
    SqlProfile.data                ||= {}
    SqlProfile.data[path]          ||= {}
    SqlProfile.data[path][segment] ||= []
    SqlProfile.data[path][segment]  << explains
  end
  
  def log_info_with_profile(sql, name, runtime)
    log_info_without_profile(sql, name, runtime)

    return unless SqlProfile.controller
    return unless /^\s*(SELECT|UPDATE|INSERT|DELETE|REPLACE)/i =~ sql

    results  = ActiveRecord::Base.connection.execute("EXPLAIN #{sql}")
    explains = [] 

    while explain = results.fetch_hash
      explain.delete('rows')
      explains << explain
    end

    add_explains(explains)
  end
end