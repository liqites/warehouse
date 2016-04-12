# print package list
module Printer
  class P001<Base
    # HEAD=[:id, :whouse, :delivery_date, :user, :total_packages]
    # BODY=[:package_id, :part_id, :quantity, :w_date, :receive_position]

    HEAD=[:forklist_nr, :create_date]
    BODY=[:jx_batchnr, :shleoninr, :czleoninr, :qty,:unit, :num_buckle, :remark]
    #拖清单和包装箱的打印模板
    def generate_data
      f=LogisticsContainer.find_by_id(self.id)
      p = f.presenter
      #
      head={
          forklist_nr: p.container_id,
          create_date: p.created_at
      }
      heads=[]

      HEAD.each do |k|
        heads<<{Key: k, Value: head[k]}
      end

      packages=LogisticsContainerService.get_packages(f)
      packages.each_with_index do |p, i|
        puts p
        body={
            # nr: i+1,
            jx_batchnr: '',
            shleoninr: p.package.extra_sh_part_id.to_s,
            czleoninr: p.package.extra_cz_part_id.to_s,
            qty: p.package.quantity.to_s,
            unit: p.package.extra_unit.to_s,
            num_buckle: 1,
            remark: p.package.remark.to_s
        }
        bodies=[]
        BODY.each do |k|
          bodies<<{Key: k, Value: body[k]}
        end
        self.data_set <<(heads+bodies)
      end


    end
  end
end
