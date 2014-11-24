require 'action_view'
include ActionView::Helpers::DateHelper


#LocationContainer.destroy_all

#transfer all old packages,forklifts,deliveries to containers.
#than build location_containers
#than add records

# *Delivery,*Forklift的所有状态都转化为到达，
# *Package中所有的状态，如果是Destination的并且Forklift也是Destination的，则修改为拒收，Rejected
# *同时，需要产生多少条Record，需要留意创建。
# *注意那些空的Package,Forklift,Delivery
class OPackage < ActiveRecord::Base

  belongs_to :user
  belongs_to :forklift

  include Extensions::UUID
  self.table_name = "packages"
end

class OForklift < ActiveRecord::Base
  include Extensions::UUID
  self.table_name = "forklifts"

  belongs_to :user
  belongs_to :delivery
  belongs_to :whouse
  has_many :packages, class_name: "OPackage", foreign_key: 'forklift_id'
end

class ODelivery < ActiveRecord::Base
  include Extensions::UUID
  self.table_name = "deliveries"

  belongs_to :user
  belongs_to :destination, class_name: 'Location'
  belongs_to :receiver, class_name: 'User'
  has_many :forklifts, class_name: "OForklift", foreign_key: 'delivery_id'
end

start_time = Time.now

#*先创建Delivery
ds = ODelivery.all.order(created_at: :desc).limit(100)

all = ds.count
ds.each_with_index do |od,index|
  ActiveRecord::Base.transaction do
    #create Delivery Container
    d = Delivery.create(id:od.id,remark: od.remark,user_id: od.user_id, location_id: od.user.location_id,created_at: od.created_at,updated_at: od.updated_at)
    processing = (((index+1).to_f/all)*100).round(4)
    time_processed = distance_of_time_in_words(Time.now - start_time)
    puts "--------------------已处理#{processing}%,耗时#{time_processed}----------------"
    #create Delivery Location_Container =>
    dlc = d.logistics_containers.build(source_location_id: od.user.location_id,user_id: od.user_id,remark: od.remark)
    dlc.destinationable = od.destination
    dlc.des_location_id = od.destination_id

    default_sender = User.where({role_id:Role.sender}).first
    default_receiver = User.where({role_id:Role.receiver}).first
    user_id = nil
    #change state
    #注意每一个record的时间，应该和od的时间一致，或者尽量保持一致
    case od.state
      when DeliveryState::ORIGINAL
        dlc.state = MovableState::INIT
      when DeliveryState::WAY
        dlc.state = MovableState::WAY
        #*record dispatch
        impl_time = od.delivery_date.nil? ? od.created_at : od.delivery_date
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:od.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
      when DeliveryState::DESTINATION
        dlc.state = MovableState::ARRIVED
        #*record dispatch
        impl_time = od.delivery_date.nil? ? od.created_at : od.delivery_date
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:od.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
        #*record receive
        impl_time = od.received_date.nil? ? od.updated_at : od.received_date
        user_id = od.receiver_id.nil? ? default_receiver : od.receiver_id
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
      when DeliveryState::RECEIVED
        dlc.state = MovableState::CHECKED
        #*record dispatch
        impl_time = od.delivery_date.nil? ? od.created_at : od.delivery_date
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:od.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
        #*record receive
        impl_time = od.received_date.nil? ? od.updated_at : od.received_date
        user_id = od.receiver_id.nil? ? default_receiver : od.receiver_id
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
        #*record check
        impl_time = od.received_date.nil? ? od.updated_at : od.received_date
        user_id = od.receiver_id.nil? ? default_receiver : od.receiver_id
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::EXAMINER,impl_action:'check',impl_time:impl_time})
      when DeliveryState::REJECTED
        dlc.state = MovableState::REJECTED
        #*record dispatch
        impl_time = od.delivery_date.nil? ? od.created_at : od.delivery_date
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:od.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
        #*record receive
        impl_time = od.received_date.nil? ? od.updated_at : od.received_date
        user_id = od.receiver_id.nil? ? default_receiver : od.receiver_id
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
        #*record rejected
        impl_time = od.received_date.nil? ? od.updated_at : od.received_date
        user_id = od.receiver_id.nil? ? default_receiver : od.receiver_id
        Record.create({recordable:dlc,destinationable:dlc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::REJECTOR,impl_action:'reject',impl_time:impl_time})
    end
    #get all forklift and added to delivery
    dlc.created_at = od.created_at
    dlc.updated_at = od.updated_at
    dlc.save
    #puts "#{d.id} => DC \n"
    #puts "#{dlc.id} => DLC \n"
    #puts "#{dlc.records.count} => DLC Records created! \n"
    od.forklifts.each do |of|
      #注意，这里只统计到了运单中的Forklift，但是没有统计到不存在晕但中的forklift
      f = Forklift.create(id:of.id,user_id:of.user_id,location_id:of.user.location_id,created_at:of.created_at,updated_at:of.updated_at,remark:of.remark)
      flc = f.logistics_containers.build(source_location_id: of.user.location_id,user_id:of.user_id,destinationable:of.whouse)

      #set state
      #create records
      case of.state
        when ForkliftState::ORIGINAL
          flc.state = MovableState::INIT
        when ForkliftState::WAY
          flc.state = MovableState::WAY
          #record dispatch
          impl_time = of.created_at
          Record.create({recordable:flc,destinationable:flc.destinationable,impl_id:of.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
        when ForkliftState::DESTINATION
          flc.state = MovableState::ARRIVED
          #record dispatch
          impl_time = of.created_at
          Record.create({recordable:flc,destinationable:flc.destinationable,impl_id:of.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
          #record receive
          impl_time = of.updated_at
          Record.create({recordable:flc,destinationable:flc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
        when ForkliftState::RECEIVED,ForkliftState::PART_RECEIVED
          flc.state = MovableState::CHECKED
          #record dispatch
          impl_time = of.created_at
          Record.create({recordable:flc,destinationable:flc.destinationable,impl_id:of.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
          #record receive
          impl_time = of.updated_at
          Record.create({recordable:flc,destinationable:flc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
          #record check
          Record.create({recordable:flc,destinationable:flc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::EXAMINER,impl_action:'check',impl_time:impl_time})
      end

      dlc.add(flc)
      flc.created_at = of.created_at
      flc.updated_at = of.updated_at
      flc.save

      #puts "#{f.id} => FC \n"
      #puts "#{flc.id} => Fflc \n"
      #puts "#{flc.records.count} => Fflc Records \n"

      #packages
      of.packages.each do |op|
        p = Package.create({id:op.id,quantity:op.quantity,user_id:op.user_id,location_id:op.location_id,fifo_time:op.check_in_time,part_id:op.part_id,created_at:op.created_at,updated_at:op.updated_at})
        plc = p.logistics_containers.build({source_location_id:op.location_id,user_id:op.user_id})

        case op.state
          when PackageState::ORIGINAL
            plc.state = MovableState::INIT
          when PackageState::WAY
            plc.state = MovableState::WAY

            #record dispatch
            impl_time = op.created_at
            Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:op.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
          when PackageState::DESTINATION
            if of.state != PackageState::ORIGINAL && of.state != PackageState::WAY
              plc.state = MovableState::REJECTED
              #record dispatch
              impl_time = op.created_at
              Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:op.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
              #record receive
              impl_time = op.updated_at
              Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
              #record rejected
              impl_time = op.updated_at
              Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::REJECTOR,impl_action:'reject',impl_time:impl_time})
            else
              plc.state = MovableState::ARRIVED

              #record dispatch
              impl_time = op.created_at
              Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:op.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
              #record receive
              impl_time = op.updated_at
              Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
            end
          when PackageState::RECEIVED
            plc.state = MovableState::CHECKED
            #record dispatch
            impl_time = op.created_at
            Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:op.user_id,impl_user_type:ImplUserType::SENDER,impl_action:'dispatch',impl_time:impl_time})
            #record receive
            impl_time = op.updated_at
            Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::RECEIVER,impl_action:'receive',impl_time:impl_time})
            #record rejected
            impl_time = op.updated_at
            Record.create({recordable:plc,destinationable:plc.destinationable,impl_id:user_id,impl_user_type:ImplUserType::EXAMINER,impl_action:'check',impl_time:impl_time})
          when PackageState::REJECTED
            plc.state = MovableState::REJECTED

        end
        flc.add(plc)
        plc.created_at = op.created_at
        plc.updated_at = op.updated_at
        plc.save

        #puts "#{p.id} => PC \n"
        #puts "#{plc.id} => PLC \n"
        #$puts "#{plc.records.count} => PLC Records \n"

      end
    end
    #puts "---------------------------------------------"
  end
end

puts "======================"
puts "=="
puts "==共耗时"+distance_of_time_in_words(Time.now - start_time)
puts "=="
puts "======================"


#transfer Old deliveries
=begin
ODelivery.all.each do |od|
  #create delivery container
  d = Delivery.create({id:od.id,state:od.state,location_id:od.location_id,user_id:od.user_id,current_position_id:od.destination_id, current_position_type:"Location"})
  #create delivery location_container
  lc = d.logistics_containers.build(source_location_id: d.location_id, user_id: d.user_id)


  #create forklift containers of delivery
  #create forklift location_container

  #add forklifts location_containers to delivery container

  #create package containers
  #create package location_containers

  #add package location_containers to forklift location_containers

  #create action record for all location_containers
end
=end

=begin
Package.all.each do |p|
  lc=p.location_containers.build
  lc.location=p.user.location if p.user
  lc.save
end
=end
