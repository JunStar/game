require 'grape-swagger'
require 'redpack/redpack_api'
require 'cards/card_api'
require 'pay/pay_api'
require 'orders/order_api'
module API
  #一个服务一个模块  小型微服务
  class Root < Grape::API
    prefix 'api'
    format :json

    mount API::RedPack::RedpackAPI
    mount API::Cards::CardAPI
    mount API::Orders::OrderAPI
    mount API::Pay::PayAPI



    #api 文档
    add_swagger_documentation
  end


end