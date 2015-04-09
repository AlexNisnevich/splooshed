class Cache
  include Singleton
  include Logging

  def initialize
    @dc = Dalli::Client.new(
      (ENV["MEMCACHIER_SERVERS"] || "localhost:11211").split(","),
      {
        :username => ENV["MEMCACHIER_USERNAME"],
        :password => ENV["MEMCACHIER_PASSWORD"],
        :namespace => "app_v1",
        :failover => true,
        :socket_timeout => 1.5,
        :socket_failure_delay => 0.2
      }
    )
  end

  def get_and_cache(key)
    value = try_lookup(key)
    if value
      value
    else
      value = yield
      try_set(key, value) if value
      value
    end
  end

  private 

  def try_lookup(key)
    begin
      value = @dc.get(key)
      log_info "Retrieving from cache: #{key} => #{value}" if value
      value
    rescue => e
      log_error e
      nil
    end
  end

  def try_set(key, value)
    begin
      @dc.set(key, value)
      log_info "Wrote to cache: #{key} => #{value}" 
    rescue
    end
  end
end