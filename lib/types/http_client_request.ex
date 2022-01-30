# HTTP client/external-endpoint specific
defprotocol Types.HTTPClientRequest do
  def execute(this, params)
end
