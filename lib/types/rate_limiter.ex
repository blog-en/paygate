defprotocol Types.RateLimiter do
  def execute(this, params)
end
