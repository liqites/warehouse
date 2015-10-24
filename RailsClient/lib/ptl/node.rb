module Ptl
  class Node

    attr_accessor :state, :color, :rate, :display, :id, :job, :job_id


    NORMAL=100 #正常
    ORDERED=200 #要货
    URGENT_ORDERED=300 #紧急要货
    PICKED=400 #择货
    DELIVERED=500 #发运
    RECEIVED=600 #接受

    # 0:全灭 1:红色
    # 2:绿色 3:蓝色
    @@state_map={
        :'100' => {state: NORMAL, color: 2, rate: 0},
        :'200' => {state: ORDERED, color: 1, rate: 0},
        :'300' => {state: URGENT_ORDERED, color: 1, rate: 1},
        :'400' => {state: PICKED, color: 3, rate: 0},
        :'500' => {state: DELIVERED, color: 3, rate: 1},
        :'600' => {state: RECEIVED, color: 2, rate: 1}
    }

    def initialize(state)
      map=Node.find_map(state)
      self.state=map[:state]
      self.color=map[:color]
      self.rate=map[:rate]
    end


    def self.where(args={})
      @@state_map.values.each do |v|
        puts v

        found=true

        args.each do |k, vv|
          puts "#{k}====#{vv}----#{v[k]}"
          if v[k]!=vv
            (found=false)
            break
          end
        end
        puts "----------#{v}"
        return self.find(v[:state]) if found

      end
    end

    def self.find_map(state)
      @@state_map[state.to_s.to_sym] || raise('No State Error')
    end

    def self.find(state)
      Node.new(state)
    end


    def set_display(urgent_size=0, order_size=0)
      urgent_size=0 if urgent_size<0
      order_size=0 if order_size<0
      # 当要货量为0时，灯变为正常状态
      if order_size==0
        map=Node.find_map(NORMAL)
        self.state=map[:state]
        self.color=map[:color]
        self.rate=map[:rate]
      end
      self.display= "#{'%02d' % urgent_size}#{'%02d' % order_size}"
    end

    def self.parse_display(display)
      return display[0..1].to_i, display[2..3].to_i
    end

    def id_format
  '%04d' %   self.id#+' '*(40-self.id.length)
    end

    def color_format
     '%02d' % self.color
    end

    def rate_format
      #'%04d' % self.rate
     '%02d' % self.rate
    end

	def dispaly_format
	 hex_s= self.display.to_i.to_s(16)
	 s=''
	 (4-hex_s.length).times{s+='0'}
	 "#{s}#{hex_s}"
	end

  end
end
