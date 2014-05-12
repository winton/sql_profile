$:.unshift File.dirname(__FILE__)

module SqlProfile
  
  def self.append_features(klass)
    super

    klass.class_eval do
      unless method_defined?(:log_info_without_profile)
        alias_method :log_info_without_profile, :log_info
        alias_method :log_info, :log_info_with_profile
      end
    end
  end
  
  def log_info_with_trace(sql, name, runtime)
    log_info_without_trace(sql, name, runtime)
    
    return unless @logger and @logger.debug?
    return if / Columns$/ =~ name

    @logger.info "!!! #{sql}"
  end
end