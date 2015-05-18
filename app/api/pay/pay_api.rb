require 'socket'
module API
  module Pay
    class PayAPI < Grape::API
      version 'v1'
      helpers do

        def generate_wx_pay_param(order)
          param_hash = Hash.new
          stamp = time_stamp
          str = nonce_str
          sort_params = [order.appid, timestamp, nonce, encrypt_msg].sort.join
          current_signature = Digest::SHA1.hexdigest(sort_params)
          sign = ""
          product = Product.find_by_id(order.product_id)
          param_hash["appid"]= order.appid
          param_hash["mch_id"] = order.mch_id
          param_hash["device_info"] = order.device_info
          param_hash["nonce_str"] = str
          param_hash["sign"] = sign
          param_hash["body"] = product.body
          param_hash["detail"] = product.detail
          param_hash["attach"] = order.attach
          param_hash["out_trade_no"] = order.out_trade_no
          param_hash["fee_type"] = order.fee_type
          param_hash["total_fee"] = order.total_fee.to_i
          param_hash["time_start"] = order.time_start
          param_hash["time_expire"] = order.time_expire
          param_hash["trade_type"] = order.trade_type
          param_hash["product_id"] = order.product_id
          param_hash["trade_type"] = order.trade_type
          param_hash["openid"] = order.openid

          if order.trade_type == "Native"
            #本机ip地址
            param_hash["spbill_create_ip"] = IPSocket.getaddress(Socket.gethostname)
          else
            #请求端的ip地址
            param_hash["spbill_create_ip"] =  request.remote_ip
          end
          param_hash["notify_url"] = "http://#{request.domain}/api/v1/pay/callback"

         end

        def time_stamp
          Time.now.to_local.to_i.to_s
        end

        def nonce_str(len = 16)
          chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
          newStr = ""
          1.upto(len) { |i| newStr << chars[rand(chars.size-1)] }
          return newStr
        end
      end

      resources :pay do
        desc "支付二维码"
        params do
          requires :order_id,type:Integer,allow_blank:false,desc:"订单的ID"
        end
        post :qrcode_url do
          order = Order.find_by_id(params["order_id"])
          error! '无效订单',401 unless order
          # 如果是微信支付
          if order.pay_type == 0
            request_url = "https://api.mch.weixin.qq.com/pay/unifiedorder"




              {"result"=>0,"qrcode_url"=>generate_wx_pay_qrcode_url(order)}
          else
            ""
          end

        end

      end




    end


  end



end