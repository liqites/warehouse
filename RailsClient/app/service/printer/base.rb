module Printer
  class Base
    attr_accessor :id,:data_set, :head, :body, :foot
    def initialize(id=nil)
      self.data_set =[]
      self.id=id
      generate_data
    end
  end
end