module Printer
  class P002<Base
    HEAD=[:id,:send_addr,:receive_addr, :delivery_date]
    BODY=[:forklift_id,:quantity,:whouse,:remark]


    def generate_data
      d=Delivery.find(self.id)
      head={id: d.id, send_addr:d.source.address,receive_addr:d.destination.address,delivery_date:d.delivery_date}
      heads=[]
      HEAD.each do |k|
        heads<<{Key: k, Value: head[k]}
      end
      forklifts=d.forklifts
      forklifts.each do |f|
        body={forklift_id:f.id,sum_packages:f.quantity,whouse:f.whouse_id,remark:f.remark}
        bodies=[]
        BODY.each do |k|
          bodies<<{Key: k, Value: body[k]}
        end
        self.data_set <<(heads+bodies)
      end
    end
  end
end