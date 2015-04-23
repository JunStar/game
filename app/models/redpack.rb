class Redpack < ActiveRecord::Base
  require 'net/https'
  require 'uri'
  require 'rexml/document'
  include REXML

  def beacon_name
    if self.beaconid
      b = Ibeacon.find self.beaconid
      return b.name if b
    end
  end

  def weixin_post(user,beaconid_url)
    uri = URI.parse('https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"  # enable SSL/TLS
    http.cert =OpenSSL::X509::Certificate.new(File.read("weixin_pay/cert/apiclient_cert.pem"))
    http.key =OpenSSL::PKey::RSA.new(File.read("weixin_pay/cert/apiclient_key.pem"), '1229344702')# key and password
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE #这个也很重要

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'text/xml'

    request.body = array_xml(user,beaconid_url)
    response = http.start do |http|
      ret = http.request(request)
      puts request.body
      puts ret.body
      doc = Document.new(ret.body)
      chapter1 = doc.root.elements[8] #输出节点中的子节点
      puts chapter1.text #输出第一个节点的包含文本
      return chapter1.text
    end
  end

  def array_xml(user,beaconid_url)
    current_redpack = get_current_redpack(beaconid_url)
    money = get_redpack_rand(beaconid_url)
    doc = Document.new"<xml/>"
    root_node = doc.root
    el14 = root_node.add_element "act_name"
    el14.text = current_redpack.action_title
    el13 = root_node.add_element "client_ip"
    el13.text = '121.42.47.121'
    el10 = root_node.add_element "max_value"
    el10.text = money
    el2 = root_node.add_element "mch_billno"
    el2.text = '1233034702'+Time.new.strftime("%Y%d%m").to_s+rand(9999999999).to_s
    el3 = root_node.add_element "mch_id"
    el3.text = '1233034702'
    el9 = root_node.add_element "min_value"
    el9.text = money
    el5 = root_node.add_element "nick_name"
    el5.text = "盛也网络公司"
    el21 = root_node.add_element "nonce_str"
    el21.text = Digest::MD5.hexdigest(rand(999999).to_s).to_s
    el22 = root_node.add_element "re_openid"
    el22.text = user.get_openid
    el16 = root_node.add_element "remark"
    el16.text = current_redpack.action_remark
    el6 = root_node.add_element "send_name"
    el6.text = current_redpack.sender_name
    el8 = root_node.add_element "total_amount"
    el8.text = money
    el11 = root_node.add_element "total_num"
    el11.text = 1
    el12 = root_node.add_element "wishing"
    el12.text = current_redpack.wishing
    el4 = root_node.add_element "wxappid"
    el4.text = WX_APPID

    stringA="act_name="+el14.text.to_s+"&client_ip="+el13.text.to_s+"&max_value="+el10.text.to_s+"&mch_billno="+el2.text.to_s+"&mch_id="+el3.text.to_s+"&min_value="+el9.text.to_s+"&nick_name="+el5.text.to_s+"&nonce_str="+el21.text.to_s+"&re_openid="+el22.text.to_s+"&remark="+el16.text.to_s+"&send_name="+el6.text.to_s+"&total_amount="+el8.text.to_s+"&total_num="+el11.text.to_s+"&wishing="+el12.text.to_s+"&wxappid="+el4.text.to_s
    stringSignTemp=stringA+"&key=wangpeisheng1234567890leapcliffW"
    puts stringSignTemp
    sign=Digest::MD5.hexdigest(stringSignTemp).upcase
    el1 = root_node.add_element "sign"
    el1.text = sign

    return doc.to_s
  end

  def get_current_redpack(beaconid_url)
    beaconid = Ibeacon.find_by(:url=>beaconid_url).id
    current_redpack = Redpack.find_by(beaconid: beaconid)
    return current_redpack
  end

  def get_redpack_rand(beaconid_url)
    rand_num = rand(10)
    current_redpack = get_current_redpack(beaconid_url)
    min = current_redpack.min*100
    max = current_redpack.max*100
    weight_1 = 0.5
    weight_2 = 0.8
    if (0..4).include?(rand_num)
      redpack_rand = (rand(min..((max-min)*weight_1+min))/100).to_i
    elsif (5..8).include?(rand_num)
      redpack_rand = (rand(((max-min)*weight_1+min)..((max-min)*weight_2+min))/100).to_i
    elsif (9..9).include?(rand_num)
      redpack_rand = (rand(((max-min)*weight_2+min)..max)/100).to_i
    end
    return redpack_rand
  end

end
