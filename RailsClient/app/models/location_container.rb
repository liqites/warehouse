class LocationContainer < ActiveRecord::Base
  include Extensions::UUID
  include Movable

  belongs_to :containerable, :polymorphic => true
  belongs_to :location
end