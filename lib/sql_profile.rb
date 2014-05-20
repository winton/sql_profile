$:.unshift File.dirname(__FILE__)

module SqlProfile

  mattr_accessor :controller
  mattr_accessor :redis
  mattr_accessor :segment
  mattr_accessor :version
  
  def self.append_features(klass)
    super

    klass.class_eval do
      unless method_defined?(:log_info_without_profile)
        alias_method :log_info_without_profile, :log_info
        alias_method :log_info, :log_info_with_profile
      end
    end
  end

  def self.around_filter(controller, segment)
    self.controller = controller
    self.segment    = segment
    yield
  ensure
    self.controller = nil
    self.segment    = nil
  end

  def add_explains(sql, explains)
    path     = SqlProfile.controller.request.path
    segment  = SqlProfile.segment
    version  = SqlProfile.version ||= `cd #{Rails.root} && git rev-parse HEAD`.strip

    redis.rpush("sql_profile:segments:#{segment}:versions:#{version}", {
      caller:   caller,
      explains: explains,
      sql:      sql
    }.to_json)

    unless redis.lrange("sql_profile:segments:#{segment}:versions", -1, -1).include?(version)
      redis.rpush("sql_profile:segments:#{segment}:versions", version)
    end
    
    redis.sadd("sql_profile:segments", segment)
  end
  
  def log_info_with_profile(sql, name, runtime)
    log_info_without_profile(sql, name, runtime)

    return unless SqlProfile.controller && redis
    return unless /^\s*(SELECT|UPDATE|INSERT|DELETE|REPLACE)/i =~ sql

    results  = ActiveRecord::Base.connection.execute("EXPLAIN #{sql}")
    explains = [] 

    while explain = results.fetch_hash
      explain.delete('rows')
      explains << explain
    end

    add_explains(sql, explains)
  end

  def redis
    SqlProfile.redis
  end
end