require 'rest-client'
require 'ptl/node'
module Ptl
  class PhaseMachine
    attr_accessor :job

    def initialize(job)
      self.job=job
    end

    def process
      # begin
        node=job.node
        displays=Node.parse_display(job.curr_display)

        puts "7. machine start process job:#{job.id}:to_state#{job.to_state}:job_node:#{job.node.id}:job_node:#{job.node.job_id}"
        case job.to_state
          when Ptl::Node::NORMAL
            # all curr states apply this method
            node.set_display(0, 0)
          when Ptl::Node::ORDERED
            result=true
            if Ptl::State::OrderState.do_order?(job.ptl_job.order_state)
              result=LedService.create_stockout_list(node.id)
              if result
                job.ptl_job.update_attributes(order_state: Ptl::State::OrderState::SUCCESS )
              end
            end
            if result
              puts '7.0 create item success...........'
              node.set_display(displays[0], displays[1]+job.size)
            end
          when Node::URGENT_ORDERED
            result=true
            if Ptl::State::OrderState.do_order?(job.ptl_job.order_state)
              result=LedService.create_stockout_list(node.id, true)
              if result
                job.ptl_job.update_attributes(order_state: Ptl::State::OrderState::SUCCESS )
              end
            end
            if result
              node.set_display(displays[0]+job.size, displays[1]+job.size)
            end
          when Node::PICKED
            # 'just change color and rate'
          when Node::DELIVERED
            # 'just change color and rate'
          when Node::RECEIVED
            node.set_display(displays[0]-job.size, displays[1]-job.size)
          else
            raise 'invalid job to state'
        end

        puts "7.1. machine update node infos"
        puts "7.2. machine update node infos:#{job.id}"

        Ptl::Message::SendParser.new(job).process

        puts "7.3. machine updated node infos:#{job.id}"
      # rescue => e
      #   puts "[#{Time.now}] error: #{e.message}"
      #   begin
      #     if ptl_job=PtlJob.find_by_id(job.id)
      #       ptl_job.update_attributes(state: Ptl::State::Job::HANDLE_FAIL, msg: e.message)
      #     end
      #   rescue => ee
      #     puts "[#{Time.now}] error: #{ee.message}"
      #   end
      # end
    end

  end
end
