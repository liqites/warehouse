class NLocation < ActiveRecord::Base
  belongs_to :parent, class_name: 'NLocation'
end