#encoding: utf-8
class OrderCarPresenter<Presenter
  Delegators=[:id, :nr, :rfid_nr, :whouse_id, :status]
  def_delegators :@order_car, *Delegators

  def initialize(order_car)
    @order_car=order_car
    self.delegators =Delegators
  end

  def as_basic_info
    if @order_car.nil?
      {}
    else
      {
          id: @order_car.id,
          nr: @order_car.nr,
          rfid_nr: @order_car.rfid_nr,
          whouse_id: @order_car.whouse_id,
          status: @order_car.status
      }
    end
  end

  def as_basic_feedback(messages=nil, result_code=nil)
    if @order_car.nil?
      {
          meta: {
              code: 400,
              error_message:'未找到该料车'
          }
      }
    else
      {
          meta: {
              code: result_code||200,
              message:'找到啦'
          },
          data: {
              id: @order_car.id,
              nr: @order_car.nr,
              rfid_nr: @order_car.rfid_nr,
              warehouse_id: @order_car.whouse_id,
              status: @order_car.status,
              leds: LedPresenter.as_basic_infos(@order_car.leds)
          }
      }
    end
  end

end