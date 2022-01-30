defprotocol Types.PaymentServiceMetrics do
  def count(this, label)
  def count(this, label, service)
end
