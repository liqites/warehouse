require 'sinatra/base'
require 'ptl/phase_machine'

module Ptl
  class Api<Sinatra::Base
    # include Sidekiq::Paginator


    get '/confirm' do

    end

    # params
    #  required: message string
    #
    get '/receive' do
      raise
    end
  end
end