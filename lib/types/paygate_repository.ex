defprotocol Types.PaygateRepository do
  def insert_finished_transactions(this, txns)
  def insert_pending_transactions(this, txns)
  def pop_all_pending_transactions(this)
end
