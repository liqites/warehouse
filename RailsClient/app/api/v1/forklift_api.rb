module V1
  class ForkliftAPI<Base
    namespace :forklifts
    guard_all!

    #strong parameters
    helpers do
      def forklift_params
        ActionController::Parameters.new(params).require(:forklift).permit(:whouse_id, :user_id, :remark, :stocker_id, :id)
      end
    end

    #get all forklifts not in delivery
    #@deprecated!
    get :binds do
      forklifts=LogisticsContainerService.get_bind_forklifts_by_location(current_user.location_id, (current_user.id if params.has_key?(:all)))
      ForkliftPresenter.init_json_presenters(forklifts)
    end

    #get forklifts by create_at time and state
    #@start_time
    #@end_time
    #@state
    #@type
    get :get_by_time_and_state do
      args= {}
      start_time = params[:start_time].nil? ? 48.hour.ago : params[:start_time]
      end_time = params[:end_time].nil? ? Time.now : params[:end_time]

      args[:state] = params[:state] if params[:state]

      if params[:type].nil? || params[:type].to_i == 0
        args[:created_at] = start_time..end_time
        args[:source_location_id] = [current_user.location_id,nil]
        args[:user_id] = current_user.id if params[:all].nil?
      else
        args['records.impl_time'] = start_time..end_time
        args['records.impl_user_type'] = ImplUserType::RECEIVER
        args[:des_location_id] = current_user.location_id
      end

      args[:ancestry]= nil

      {result:1,content:ForkliftPresenter.init_json_presenters(ForkliftService.search(args).order(created_at: :desc).all)}
    end

    # create forklift
    post do
      args=forklift_params
      args.delete(:stocker_id)
      args[:destinationable_id] = args[:whouse_id]
      args.delete(:whouse_id)

      msg = ForkliftService.create(args, current_user)
      msg.result ? {result: 1, content: ForkliftPresenter.new(msg.object).to_json} : {result: 0, content: msg.content}
    end

    #@deparecated
    #*test api*
    post :add do
      p1=LogisticsContainer.build(params[:id], current_user.id, current_user.location_id)
      p2=LogisticsContainer.build(params[:pid], current_user.id, current_user.location_id)

      p1.add(p2)
    end

    #check if a package can be add to a forklift
    #if can,add to the forklift
    #if not,return

    # add package
    post :check_package do
      m = ApiMessage.new

      unless f=LogisticsContainer.exists?(params[:id])
        return {result: 0, result_code: ResultCodeEnum::Failed, content: ForkliftMessage::NotExit}
      end

      unless f.can_update?
        return {result: 0, result_code: ResultCodeEnum::Failed, content: ForkliftMessage::CannotUpdate}
      end

      unless pc= Package.exists?(params[:package_id])
        return {result: 0, result_code: ResultCodeEnum::Failed, content: PackageMessage::NotExit}
      end

      # 在当前的逻辑中，不会存在一个container没有任何的location_container
      # 如果一个Package 没有任何container，则不能添加到拖清单中
      if pc.logistics_containers.count == 0
        return m.set_false("不能添加包装箱，包装箱已被删除!")
      end

      unless p=LogisticsContainer.build(params[:package_id], current_user.id, current_user.location_id)
        p=pc.logistics_containers.build(source_location_id: current_user.location_id, user_id: current_user.id)
        p.destinationable = f.destinationable
        p.save
      end

      unless p.can_update?
        return {result:0,result_code: ResultCodeEnum::Failed,content: PackageMessage::Sent}
      end

      p.package=pc

      unless p.can_add_to_container?
        return {result: 0, result_code: ResultCodeEnum::Failed, content: PackageMessage::InOtherForklift}
      end

      if f.add(p)
        if PartService.get_part_by_id_whouse_id(pc.part_id, f.destinationable_id)
          {result: 1, result_code: ResultCodeEnum::Success, content: PackagePresenter.new(p).to_json}
        else
          {result: 1, result_code: ResultCodeEnum::TargetNotInPosition, content: PackagePresenter.new(p).to_json}
        end
      else
        {result: 0, result_code: ResultCodeEnum::Failed, content: ForkliftMessage::AddPackageFailed}
      end
    end

    get :packages do
      unless f=LogisticsContainer.exists?(params[:id])
        return {result: 0, result_code: ResultCodeEnum::Failed, content: ForkliftMessage::NotExit}
      end

      fpresenter = ForkliftPresenter.new(f)

      {result:1,content:PackagePresenter.init_json_presenters(fpresenter.packages)}
    end

    # add package
    # create package and add it to forklift
    # @deprecated
    # * use api create package and add it forklift
    post :add_package do
      unless f=LogisticsContainer.exists?(params[:id])
        return {result: 0, result_code: ResultCodeEnum::Failed, content: ForkliftMessage::NotExit}
      end

      unless f.can_update?
        return {result: 0, content: ForkliftMessage::CannotUpdate}
      end

      args = {
          id: params[:package_id],
          part_id: params[:part_id],
          part_id_display: params[:part_id_display],
          quantity: params[:quantity],
          quantity_display: params[:quantity_display],
          custom_fifo_time: params[:fifo_time],
          fifo_time_display: params[:fifo_time_display]
      }
      #
      res = PackageService.create(args, current_user)
      if res.result
        lc_p = res.object
        if f.add(lc_p)
          lc_p.update({destinationable:f.destinationable})
          if PartService.get_part_by_id_whouse_id(params[:part_id], f.destinationable_id)
            {result: 1, result_code: ResultCodeEnum::Success, content: PackagePresenter.new(lc_p).to_json}
          else
            {result: 1, result_code: ResultCodeEnum::TargetNotInPosition, content: PackagePresenter.new(lc_p).to_json}
          end
        else
          {result: 0, result_code: ResultCodeEnum::Failed, content: ForkliftMessage::AddPackageFailed}
        end
      else
        {result: 0, result_code: ResultCodeEnum::Failed, content: res.content}
      end
    end

    # remove package
    # remove a package from forklift
    delete :remove_package do
      unless (p=LogisticsContainer.exists?(params[:package_id]))
        return {result: 0, content: PackageMessage::NotExit}
      end

      unless p.can_update?
        return {result: 0, content: PackageMessage::CannotUpdate}
      end
      {result: p.remove ? 1 : 0, content: ''}
    end

    #delete forklift
    delete do
      msg = LogisticsContainerService.destroy_by_id(params[:id])
      if msg.result
        {result: 1, content: BaseMessage::DESTROYED}
      else
        {result: 0, content: msg.content}
      end
    end

    # get forklift detail
    # get the detail of a forklift,including the package
    get :detail do
      if f= LogisticsContainer.find_by_id(params[:id])
        fp = ForkliftPresenter.new(f)
        {result: 1, content: fp.to_json}
      else
        {reuslt: 0, content: ForkliftMessage::NotExit}
      end
    end

# update forklift
    put do
      args=forklift_params
      args.delete(:stocker_id)
      args[:destinationable_id] = args[:whouse_id]
      args.delete(:whouse_id)

      unless f=LogisticsContainer.exists?(args[:id])
        return {result: 0, content: ForkliftMessage::NotExit}
      end

      unless f.can_update?
        return {result: 0, content: ForkliftMessage::CannotUpdate}
      end

      unless args[:destinationable_id].blank?
        unless PartService.parts_in_whouse?(LogisticsContainerService.get_part_ids(f), args[:destinationable_id])
          return {return: 0, content: ForkliftMessage::CannotUpdatePartsNotExistInWhouse}
        end
      end

      if f.update_attributes(args)
        if args[:destinationable_id]
          packages = PackagePresenter.init_presenters(LogisticsContainerService.get_packages_with_detail(f)).collect { |p| p.to_json }
          {result: 1, content: {packages: packages}}
        else
          {result: 1, content: ForkliftMessage::UpdateSuccess}
        end

      else
        {result: 0, content: ForkliftMessage::UpdateFailed}
      end
    end

    post :send do
      msg = ApiMessage.new

      unless lc = LogisticsContainer.exists?(params[:id])
        return msg.set_false(MovableMessage::TargetNotExist)
      end

      unless lc.can_update?
        return msg.set_false(ForkliftMessage::CannotUpdate)
      end

      unless destination = Location.find_by_id(params[:destination_id])
        return msg.set_false(MovableMessage::DestinationNotExist)
      end

      unless (r = ForkliftService.dispatch(lc,destination,current_user)).result
        return msg.set_false(r.content)
      end

      return msg.set_true(MovableMessage::Success)
    end

    post :receive do
      #这里的id其实是container_id，因为扫描的是运单号
      unless f = LogisticsContainer.find_latest_by_container_id(params[:id])
        return {return: 0, content: MovableMessage::TargetNotExist}
      end

      unless f.root?
        return {return: 0, content: ForkliftMessage::InDeliveryCannotReceive}
      end

      #*own implementation of receive
      if (r = ForkliftService.receive(f,current_user)).result
        {result: 1, content: ForkliftPresenter.new(f).to_json}
      else
        {result: 0, content: r.content}
      end
    end

    #确认接收
    post :confirm_receive do
      unless lc = LogisticsContainer.exists?(params[:id])
        return {result: 0, content: DeliveryMessage::NotExit}
      end

      unless (m = ForkliftService.confirm_receive(lc,current_user)).result
        return {result:0,content: DeliveryMessage::ReceiveFailed}
      end

      return {result:1,content: DeliveryMessage::ReceiveSuccess}
    end
  end
end