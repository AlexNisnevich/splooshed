class Cache
  include Singleton

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
      try_set(key, value)
      value
    end
  end

  private 

  def try_lookup(key)
    begin
      value = @dc.get(key)
      puts "Retrieving from cache: #{key} => #{value}" if value
      value
    rescue => e
      puts e
      nil
    end
  end

  def try_set(key, value)
    @dc.set(key, value) rescue nil
  end
end