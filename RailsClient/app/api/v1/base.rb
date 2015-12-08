module V1
  class Base < ApplicationAPI
    include APIGuard
    version 'v1', :using => :path
    mount UserAPI
    mount PackageAPI
    mount PartAPI
    mount ForkliftAPI
    mount DeliveryAPI
    mount RegexAPI
    mount OrderAPI
    mount OrderItemAPI
    mount IosUpdateAPI
    mount LedAPI
    mount MovableAPI
    mount LocationAPI
    mount StorageAPI
    mount MovableAPI
    mount MovingAPI
  end
end
