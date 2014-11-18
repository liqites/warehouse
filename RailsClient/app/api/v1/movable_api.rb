
module V1
  class MovableAPI<Base
    namespace :movables
    guard_all!

    #
    helpers do
      def movable_params
        ActionController::Parameters.new(params).require(:movable).permit(:id)
      end
    end

    post :dispatch do
      msg = ApiMessage.new
      lc = LogisticsContainer.exists?(params[:id])
      unless lc
        return msg.set_false(MovableMessage::TargetNotExist).to_json
      end

      destination = LocationService.search({id:params[:destination_id]})

      unless destination
        return msg.set_false(MovableMessage::DestinationNotExist).to_json
      end

      unless (r = LogisticsContainerService.dispatch(lc,destination,current_user)).result
        return msg.set_false(r.content).to_json
      end
      msg.set_true(MovableMessage::Success).to_json
    end

    post :receive do
      msg = ApiMessage.new
      lc = LogisticsContainer.exists?(params[:id])

      unless lc
        return msg.set_false(MovableMessage::TargetNotExist).to_json
      end

      unless (r = LogisticsContainerService.receive(lc,current_user)).result
        return msg.set_false(r.content).to_json
      end

      return msg.set_true(MovableMessage::Success).to_json
    end

    post :check do
      msg = ApiMessage.new
      lc = LogisticsContainer.exists?(params[:id])

      unless lc
        return msg.set_false(MovableMessage::TargetNotExist).to_json
      end

      unless (r = LogisticsContainerService.check(lc,current_user)).result
        return msg.set_false(r.content).to_json
      end

      return msg.set_true(MovableMessage::Success).to_json
    end

    post :reject do
      msg = ApiMessage.new

      lc = LogisticsContainer.exists?(params[:id])

      unless lc
        return msg.set_false(MovableMessage::TargetNotExist).to_json
      end

      unless (r = LogisticsContainerService.reject(lc,current_user)).result
        return msg.set_false(r.content).to_json
      end

      return msg.set_true(MovableMessage::Success).to_json
    end
  end
end