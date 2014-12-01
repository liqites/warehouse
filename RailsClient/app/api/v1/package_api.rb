module V1
  class PackageAPI<Base
    namespace :packages
    guard_all!

    #strong parameters
    helpers do
      def package_params
        ActionController::Parameters.new(params).require(:package).permit(:id, :part_id, :part_id_display, :quantity, :quantity_display,
                                                                          :custom_fifo_time, :fifo_time_display)
      end
    end

    #******
    #need to add conditions for search
    #******
    # binded but not add to forklift packages
    # no need to show position
    #@deprecated
    #use api get_by_time_and_state instead
    get :binds do
      packages = PackageService.get_bind_packages_by_location(current_user.location_id, (current_user.id if params.has_key?(:all)))

      PackageLazyPresenter.init_json_presenters(packages)
    end

    #get packages by created_at time and state
    #@start_time
    #@end_time
    #@state
    #@type
    #@parent
    get :get_by_time_and_state do
      start_time = params[:start_time].nil? ? 24.hour.ago : params[:start_time]
      end_time = params[:end_time].nil? ? Time.now : params[:end_time]
      args = {
          created_at: (start_time..end_time),
      }
      args[:state] = params[:state] if params[:state]
      args[:user_id] = current_user.id if params[:all].nil?

      if params[:type].nil? || params[:type].to_i == 0
        args[:source_location_id] = [current_user.location_id,nil]
        args[:user_id] = current_user.id
      else
        args[:des_location_id] = current_user.location_id
      end

      PackageLazyPresenter.init_json_presenters(PackageService.search(args).order(created_at: :desc).all)
    end

    # validate package id
    # @deprecated
    # use validate_id instead
    post :validate do
      if Package.id_valid?(params[:id])
        {result: 1, content: ''}
      else
        {result: 0, content: PackageMessage::IdNotValid}
      end
    end

    #validate package id
    get :validate_id do
      if Package.id_valid?(params[:id])
        {result: 1, content: ''}
      else
        {result: 0, content: PackageMessage::IdNotValid}
      end
    end

    # validate quantity string
    # @deprecated
=begin
    post :validate_quantity do
      result = true #PackageService.quantity_string_valid?(params[:id])
      if result
        {result: 1, content: ''}
      else
        {result: 0, content: PackageMessage::QuantityStringError}
      end
    end
=end

    # create package
    # if find deleted then update(take care of foreign keys)
    # else create new
    post do
      m = PackageService.create package_params, current_user
      m.result ? {result: 1, content: PackageLazyPresenter.new(m.object).to_json} : {result: 0, content: m.content}
    end

    # update package
    put do
      msg = PackageService.update(package_params)
      if msg.result
        {result: 1, content: PackageLazyPresenter.new(msg.object).to_json}
      else
        {result: 0, content: msg.content}
      end
    end

    # delete package
    # update is_delete to true
    delete do
      msg = LogisticsContainerService.destroy_by_id(params[:id])
      if msg.result
        {result: 1, content: BaseMessage::DESTROYED}
      else
        {result: 0, content: msg.content}
      end
    end

    # check package
    post :check do
      msg = ApiMessage.new
      unless  p = LogisticsContainer.exists?(params[:id])
        return msg.set_false(MovableMessage::TargetNotExist)
      end
      if (r = p.get_movable_service.check(p, current_user)).result
        return msg.set_true(r.content)
      else
        return msg.set_false(r.content)
      end
    end

    # uncheck package
    # as reject a package
    post :uncheck do
      #msg = PackageService.uncheck(params[:id])
      msg = ApiMessage.new
      unless  p = LogisticsContainer.exists?(params[:id])
        return msg.set_false(MovableMessage::TargetNotExist)
      end
      if (r = p.get_movable_service.reject(p, current_user)).result
        return msg.set_true(r.content)
      else
        return msg.set_false(r.content)
      end
    end

    post :reject do
      msg = ApiMessage.new
      unless p = LogisticsContainer.exists?(params[:id])
        return msg.set_false(MovableMessage::TargetNotExist)
      end

      if (r = p.get_movable_service.reject(p, current_user)).result
        msg.set_true(r.content)
      else
        msg.set_false(r.content)
      end
    end

    post :receive do
      msg = ApiMessage.new
      unless p = LogisticsContainer.find_latest_by_container_id(params[:id])
        return msg.set_false(MovableMessage::TargetNotExist)
      end

      if(r = PackageService.receive(p,current_user)).result
        return msg.set_true(PackageLazyPresenter.new(p).to_json)
      else
        msg.set_false(r.content)
      end

    end

    post :send do
      msg = ApiMessage.new

      unless lc = LogisticsContainer.exists?(params[:id])
        return msg.set_false(PackageMessage::NotExit)
      end

      unless lc.can_update?
        return msg.set_false(PackageMessage::CannotUpdate)
      end

      unless destination = Location.find_by_id(params[:destination_id])
        return msg.set_false(MovableMessage::DestinationNotExist)
      end

      unless (r = PackageService.dispatch(lc,destination,current_user)).result
        return msg.set_false(r.content)
      end

      return msg.set_true(MovableMessage::Success)
    end

    #确认接收
    post :confirm_receive do
      unless lc = LogisticsContainer.exists?(params[:id])
        return {result: 0, content: DeliveryMessage::NotExit}
      end

      return {result:1,content: DeliveryMessage::ReceiveSuccess}
    end
  end
end