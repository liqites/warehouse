require 'ptl/type/confirm_msg_type'
require 'ptl/state/job'


module Ptl
	module Message
		class ConfirmParser<Parser
			def initialize(message)
				self.type=message[1].to_i
				self.msg_id=message[2,7].strip
				self.server_id=message[8,10]
        self.handle_state=message[11].to_i
			end

			def process
				if job=PtlJob.find_by_id(self.msg_id)
					job.update_attributes(state:get_job_state,msg: ConfirmMsgType.msg(self.handle_state))
				end
			end

			def get_job_state
				case self.type
				when ConfirmMsgType::SEND_SUCCESS
					Ptl::State::Job::SEND_SUCCESS
				else
					Ptl::State::Job::HANDLE_FAIL
				end
			end
		end
	end
end
