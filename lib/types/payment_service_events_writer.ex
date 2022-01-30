defprotocol Types.PaymentServiceEventsWriter do
  def execute(this, events)
end
