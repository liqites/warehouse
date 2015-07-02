ScrapListItem.transaction do
  ScrapListItem.where(scrap_list_id: [11, 12]).all.each do |item|
    puts "-------#{item.to_json}"
    params1={
        partNr: item.part_id,
        qty: item.quantity,
        toWh: '3EX',
        toPosition: '3EX',
        fromWh: 'BaofeiKu'
    }

    WhouseService.new.move(params1)


    params={
        partNr: item.part_id,
        qty: item.quantity,
        toWh: item.scrap_list.dse_warehouse,
        toPosition: 'BaofeiWeizhi',
        fromWh: item.scrap_list.src_warehouse
    }
    puts "#{params.to_json}"
    WhouseService.new.move(params)

  end
end