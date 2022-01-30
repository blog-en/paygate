# HTTP client/external-endpoint specific
defprotocol Types.HTTPClientResponse do
  def process_response(this, result)
end
