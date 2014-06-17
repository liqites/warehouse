require_relative 'base/custom_id_sync_base'
module Sync
  class DeliverySync< CustomIdSyncBase
    PULL_URL= BASE_URL+'deliveries'
    POST_URL= BASE_URL+'deliveries'

    def self.pull_block
      Delivery.skpi_callback(:save, :after, :log_state)
      super
    end
  end
end
