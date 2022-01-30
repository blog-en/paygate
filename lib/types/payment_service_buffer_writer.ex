defprotocol Types.PaymentServiceBufferWriter do
  def insert_finished_transaction(this, txn)
  def insert_pending_transaction(this, txn)
end
