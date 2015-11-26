module V3
  class MovementListApi < Base
    namespace :movement_list do
      guard_all!

      format :json
      rescue_from :all do |e|
        Rack::Response.new([e.message], 500).finish
      end

      desc 'get history movement list'
      params do
        requires :user_id, type: String, desc: 'movement list builder'
      end
      get do
        time_condition = 7.days.ago.utc...Time.now.utc
        args = []
        movement_lists = MovementList.where(created_at: time_condition, builder: params[:user_id]).order(created_at: :desc)
        if movement_lists
          movement_lists.each_with_index do |movement_list, index|
            record = {}
            record[:id] = movement_list.id
            record[:created_at] = movement_list.created_at
            record[:count] = movement_list.movements.count
            record[:state] = MovementListState.display movement_list.state.to_i
            args[index] = record
          end
          {result: 1, content: args}
        else
          {result: 0, content: "没有数据！"}
        end
      end

      desc 'create movement list'
      params do
        requires :user_id, type: String, desc: 'ID of the movement list builder'
        optional :remarks, type: String
      end
      post do
        if params[:user_id] && User.find_by(id: params[:user_id]).blank?
          return {result: 0, content: "#{params[:user_id]}用户不存在！"}
        end

        movement_list = MovementList.new(builder: params[:user_id], name: "#{params[:user_id]}#{DateTime.now.strftime("%H.%d.%m.%Y")}", remarks: params[:remarks])
        if movement_list.save
          {result: 1, content: {id: movement_list.id, created_at: movement_list.created_at, count: 0, state: MovementListState::BEGINNING}}
        else
          {result: 0, content: "创建失败！"}
        end
      end

      desc 'delete movement list'
      params do
        requires :movement_list_id, type: String, desc: 'ID of the movement list'
      end
      delete do
        return {result: 0, content: "#{params[:movement_list_id]}移库单不存在或者该移库单不可删除！"} unless m=MovementList.where(id: params[:movement_list_id]).where("state != #{MovementListState::ENDING}")

        m.destroy
        {result: 1, content: "删除成功"}
      end

      desc 'validate movement' #store in class variable
      params do
        requires :movement_list_id, type: String, desc: 'movement list id'
        requires :toWh, type: String, desc: 'des whouse'
        requires :toPosition, type: String, desc: 'des position'
        requires :fromWh, type: String, desc: 'src whouse'
        optional :fromPosition, type: String, desc: 'src position'
        optional :packageId, type: String, desc: 'package ID'
        optional :partNr, type: String, desc: 'part NO.'
        optional :qty, type: String, desc: 'quantity'
      end
      post :validate_movement do
        params[:toWh]=params[:toWh].sub(/LO/, '')
        params[:toPosition]=params[:toPosition].sub(/LO/, '')
        params[:fromWh]=params[:fromWh].sub(/LO/, '') if params[:fromWh].present?
        params[:fromPosition]=params[:fromPosition].sub(/LO/, '') if params[:fromPosition].present?
        params[:partNr]=params[:partNr].sub(/P/, '') if params[:partNr].present?
        puts "#{params.to_json}-----------"

        return {result: 0, content: "#{params[:movement_list_id]}移库单不存在！"} unless m=MovementList.find_by(id: params[:movement_list_id])

        begin
          params[:qty]=params[:qty].sub(/Q/, '').to_f if params[:qty].present?
          if params[:partNr].blank? && params[:packageId].blank?
            raise '请填写零件号或者唯一码'
          end
          if params[:partNr].present?
            raise '请填写数量' unless params[:qty].present?
            params[:packageId]=nil
          end

          msg = FileHandler::Excel::NStorageHandler.validate_move_row params
        rescue => e
          if params[:uniq].blank?
            return {result: 0, content: e.message}
          else
            raise e.message
          end
        end

        if msg.result
          m.update(state: MovementListState::PROCESSING)
          {result: 1, content: '数据验证通过.'}
        else
          {result: 0, content: msg.content}
        end

      end

      desc 'save movements'
      params do
        requires :movement_list_id, type: String, desc: 'movement list id'
        requires :employee_id, type: String, desc: 'The operator id'
        optional :remarks, type: String, desc: 'note info'
      end
      post :save_movements do
        msg = Message.new(contents: [])
        args = {}
        args[:movement_list_id] = params[:movement_list_id]
        args[:employee_id] = params[:employee_id].sub(/\.0/, '') if params[:employee_id].present?
        args[:remarks] = params[:remarks] if params[:remarks].present?
        args[:user] = current_user

        return {result: 0, content: "#{params[:movement_list_id]}移库单不存在！"} unless m=MovementList.find_by(id: params[:movement_list_id])

        if params[:movements].blank?
          {result: 0, content: '没有数据移库'}
        else
          NStorage.transaction do
            params[:movements].each_with_index do |movement, index|
              puts movement
              args[:toWh] = movement[:toWh].sub(/LO/, '')
              args[:toPosition] = movement[:toPosition].sub(/LO/, '')
              args[:fromWh] = movement[:fromWh].sub(/LO/, '') if movement[:fromWh].present?
              args[:fromPosition] = movement[:fromPosition].sub(/LO/, '') if movement[:fromPosition].present?
              args[:partNr] = movement[:partNr].sub(/P/, '') if movement[:partNr].present?
              args[:qty] = movement[:qty].sub(/Q/, '').to_f if movement[:qty].present?

              begin
                if movement[:partNr].present?
                  raise '请填写数量' unless movement[:qty].present?
                  args[:packageId]=nil
                end

                WhouseService.new.move(args)

              rescue => e
                m.update(state: MovementListState::ERROR)
                msg.contents << e.message
              end
            end
          end

          if msg.result=(msg.contents.size==0)
            m.update(state: MovementListState::ENDING)
            msg.content='移库成功'
          else
            msg.content=msg.contents.join('/')
          end
        end
        msg
      end


    end
  end
end