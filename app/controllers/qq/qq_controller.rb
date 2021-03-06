class Qq::QqController < ActionController::Base

  protect_from_forgery with: :exception

  #require "#{Rails.root}/lib/qzone/command/client.rb"

  before_action :set_header_for_qq
  layout "qq/layouts/qq_game"

  before_action :get_platform_info
  before_action :get_user_info


  rescue_from StandardError do |exception|
    new_logger = Logger.new('log/qq_exceptions.log')
    new_logger.info("THIS IS A NEW EXCEPTION! #{Time.now.to_s}")
    new_logger.info("------ #{request.remote_ip} ------")
    new_logger.info(request.url)
    new_logger.info(params.to_s)
    new_logger.info(exception.message)
    new_logger.info(exception.backtrace.join("\n"))
    raise exception
  end



  CONFIG = {
      qzone: {
          'appid' => '1101255082',
          'appkey' => 'rwgnIjHffqSXS4D3',
          'host' => '119.147.19.43'
      }
  }.freeze

  private
  def set_header_for_qq
    response.headers["X-Frame-Options"] = "Allow-From http://rc.qzone.qq.com"
  end

  def get_platform_info
    unless params[:openid].blank?
      @openid = params[:openid]
      @openkey = params[:openkey]
      @pf = params[:pf] || "qzone"
    end
  end

  def get_user_info

    unless params[:openid].blank?
      #@user_info = Qzone::Command::Client.new(path: '/v3/user/get_info', params: {openid: params[:openid], openkey: params[:openkey], pf: params[:pf]}).fetch
    end

    #unless params[:openid].blank?
    #  test_url = "http://119.147.19.43/v3/user/get_info"
    #  url = "http://openapi.tencentyun.com/v3/user/get_info"
    #
    #  p = {:openid => @openid, :openkey => @openkey, :appid => @appid, :pf => @pf, :fornat => "json"}
    #
    #  uri = "/v3/user/get_info"
    #
    #  encoded_uri = CGI.escape(uri)
    #  query_p = CGI.escape(p.to_query)
    #  request_method = "GET"
    #
    #  str = "#{request_method}&#{query_p}&#{encoded_uri}"
    #  secret_key = "#{@appkey}&"
    #
    #  digest = OpenSSL::Digest::Digest.new('sha1')
    #  @signature = Base64.encode64(OpenSSL::HMAC.digest(digest, secret_key, str))
    #
    #  p[:sig] = @signature
    #
    #  response = RestClient.get url, {:params => p}
    #  @qq_user = response
    #end
  end


end