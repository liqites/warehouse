# encoding: utf-8
class ReportsController < ApplicationController
  def entry_report
    @location_id = params[:location_id].nil? ? current_user.location_id : params[:location_id]
    @received_date_start = params[:received_date_start].nil? ? 1.day.ago.strftime("%Y-%m-%d 7:00") : params[:received_date_start]
    @received_date_end = params[:received_date_end].nil? ? Time.now.strftime("%Y-%m-%d 7:00") : params[:received_date_end]
    time_range = Time.parse(@received_date_start).utc..Time.parse(@received_date_end).utc
    @type=params[:type].nil? ? "total" : params[:type]

    condition = {}
    condition["deliveries.destination_id"] = @location_id
    condition["deliveries.received_date"] = time_range

    case @type
      when "total"
        condition["deliveries.state"] = [DeliveryState::WAY,DeliveryState::DESTINATION,DeliveryState::RECEIVED]
      when "received"
        condition["packages.state"] = [PackageState::RECEIVED]
      when "rejected"
        condition["packages.state"] = [PackageState::DESTINATION]
    end
    @packages = Package.joins(:part).joins(forklift: :delivery)
    .where(condition)
    .select("parts.unit_pack as upack,packages.state,packages.part_id,COUNT(packages.id) as count,forklifts.whouse_id as whouse_id,deliveries.received_date as rdate,deliveries.receiver_id as receover_id,deliveries.id as did")
    .group("packages.part_id").order("rdate DESC,did,whouse_id")
    render
  end

  def removal_report
    @location_id = params[:location_id].nil? ? current_user.location_id : params[:location_id]
    @received_date_start = params[:received_date_start].nil? ? 1.day.ago.strftime("%Y-%m-%d 7:00") : params[:received_date_start]
    @received_date_end = params[:received_date_end].nil? ? Time.now.strftime("%Y-%m-%d 7:00") : params[:received_date_end]
    time_range = Time.parse(@received_date_start).utc..Time.parse(@received_date_end).utc
    @type=params[:type].nil? ? "total" : params[:type]

    condition = {}
    condition["deliveries.source_id"] = @location_id
    condition["deliveries.delivery_date"] = time_range

    case @type
      when "total"
        condition["deliveries.state"] = [DeliveryState::WAY,DeliveryState::DESTINATION,DeliveryState::RECEIVED]
      when "send"
        condition["packages.state"] = [PackageState::RECEIVED]
      when "rejected"
        condition["packages.state"] = [PackageState::DESTINATION]
    end
    @packages = Package.joins(:part).joins(forklift: :delivery)
    .where(condition)
    .select("parts.unit_pack as upack,packages.state,packages.part_id,COUNT(packages.id) as count,forklifts.whouse_id as whouse_id,deliveries.delivery_date as ddate,deliveries.user_id as sender_id,deliveries.id as did")
    .group("packages.part_id").order("ddate DESC,did ,whouse_id ")
    render
  end

  def entry_download
  end

  def removal_download

  end
end
