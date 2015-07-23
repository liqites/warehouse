module Ptl
  class Job

	  # led_id 是4位数字字符串
	  # server_id 是3位数字字符串
	  attr_accessor :id, :led_id, :curr_state, :to_state, :curr_display, :size, :server_id,:server_url,:in_time #, :http_type

    DEFAULT_HTTP_TYPE='POST'
    DEFAULT_RETRY_TIMES=3
    DEFAULT_PROCESS_SIZE=50
	DEFAULT_IN_TIME=false

	INT_FIELD=[:curr_state,:to_state,:size]

    def initialize(options={})
      self.size=1
	  self.in_time=DEFAULT_IN_TIME

      raise 'params is blank' if options.blank?
      options.each do |k, v|
        self.instance_variable_set("@#{k}", v)
      end
	  
	  INT_FIELD.each do |f|
		  if v=self.send(f)
			  self.send f,v.to_i
		  end
	  end
    end

    def en_queue
      begin
        params={}
        self.instance_variable_names.each do |name|
          params[name.sub(/@/, '').to_sym]=self.instance_variable_get(name)
        end
        PtlJob.create(
            params: params.to_json
        )
      rescue
        return false
      end
      true
    end

    # def self.to_process(size=DEFAULT_PROCESS_SIZE)
    #   PtlJob.where.not(state: State::Job::UN_HANDLE).order(:created).limit(size)
    # end
    #

    def self.out_queue
      if job_data= PtlJob.where.not(state: State::Job::UN_HANDLE).order(:created).first
        params=JSON.parse(job_data.params).deep_symbolize_keys
		job=self.new(params)
		job.process
      end
    end

	def process
		PhaseMachine.new(self).process
	end
  end
end
