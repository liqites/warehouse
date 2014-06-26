module V1
  module Sync
    class DeliverySyncAPI<SyncBase
      namespace 'deliveries'
      rescue_from :all do |e|
        DeliverySyncAPI.error_unlock_sync_pool('deliveries')
        Rack::Response.new([e.message], 500).finish
      end
      get do
        Delivery.unscoped.where('updated_at>=?', params[:last_time]).all
      end

      post do
        deliveries=JSON.parse(params[:delivery])
        deliveries.each do |delivery|
          delivery=Delivery.new(delivery)
          delivery.save
        end
      end

      put '/:id' do
        deliveries=JSON.parse(params[:delivery])
        deliveries.each do |delivery|
          if u=Delivery.unscoped.find_by_id(delivery['id'])
            u.update(delivery.except('id'))
          end
        end
      end

      post :delete do
        deliveries=JSON.parse(params[:delivery])
        deliveries.each do |id|
          if delivery=Delivery.unscoped.find_by_id(id)
            delivery.update(is_delete: true)
          end
        end
      end
    end
  end
end