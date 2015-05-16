class Redpack < ActiveRecord::Base

  require 'net/https'
  require 'uri'
  require 'rexml/document'
  include REXML
  
  belongs_to :ibeacon


  def title
    self.action_title
  end

  def beacon_name
    if self.beaconid
      b = Ibeacon.find self.beaconid
      return b.name if b
    end
  end

  def cloning(recursive=false)
    Redpack.create self.attributes.except!("created_at", "id")
  end


  def weixin_post(user,beaconid_url,  money=nil)
    beacon = Ibeacon.find_by_url(beaconid_url)
    return unless beacon
    m = beacon.get_merchant    

    uri = URI.parse('https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"  # enable SSL/TLS
    http.cert =OpenSSL::X509::Certificate.new(File.read(m.certificate))
    http.key =OpenSSL::PKey::RSA.new(File.read(m.rsa), m.rsa_key)# key and password
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE #这个也很重要

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'text/xml'

    request.body = array_xml(user,beaconid_url, m, money)
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

  def array_xml(user,beaconid_url, m, money=nil)
    current_redpack = get_current_redpack(beaconid_url)
    money = get_redpack_rand(beaconid_url) unless money
    doc = Document.new"<xml/>"
    root_node = doc.root
    el14 = root_node.add_element "act_name"
    el14.text = current_redpack.action_title
    el13 = root_node.add_element "client_ip"
    el13.text = '121.42.47.121'
    el10 = root_node.add_element "max_value"
    el10.text = money
    el2 = root_node.add_element "mch_billno"
    el2.text = m.mch_id.to_s + Time.new.strftime("%Y%d%m").to_s+rand(9999999999).to_s
    el3 = root_node.add_element "mch_id"
    el3.text = m.mch_id.to_s
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
    el4.text = m.wxappid

    stringA="act_name="+el14.text.to_s+"&client_ip="+el13.text.to_s+"&max_value="+el10.text.to_s+"&mch_billno="+el2.text.to_s+"&mch_id="+el3.text.to_s+"&min_value="+el9.text.to_s+"&nick_name="+el5.text.to_s+"&nonce_str="+el21.text.to_s+"&re_openid="+el22.text.to_s+"&remark="+el16.text.to_s+"&send_name="+el6.text.to_s+"&total_amount="+el8.text.to_s+"&total_num="+el11.text.to_s+"&wishing="+el12.text.to_s+"&wxappid="+el4.text.to_s
    stringSignTemp=stringA+"&key=" + m.key
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

  def get_redpack_times
    if self.id
      RedpackTime.where(:redpack_id => self.id)
    else
      []
    end
  end

  def get_redpack_values
    if self.id
      RedpackValue.where(:redpack_id => self.id)
    else
      []
    end
  end

  def get_redpack_people
    if self.id
      RedpackPerson.where(:redpack_id => self.id)
    else
      []
    end
  end

  def self.first_allocation(user_id, game_id,redpack,beaconid) 
    beaconid = Ibeacon.find_by(:url=>beaconid).id
    redpack_time = RedpackTime.where(:redpack_id =>redpack.id).order("start_time desc")[0]
    person_num = redpack_time.person_num
    time_amount = TimeAmount.find_by("time_end > ? and time < ? and redpack_time_id = ? ", Time.now, Time.now, redpack_time.id)
    if time_amount.amount > 0
      min = redpack_time.min
      max = redpack_time.max
      record_allocation = time_amount.amount > min ? rand(min..max) : min
      record_score = rand((min/person_num)..(record_allocation/person_num))
      time_amount.update(:amount => (time_amount.amount - record_allocation))
      UserAllocation.create(:user_id => user_id, :allocation => (record_allocation -record_score), :num => (person_num - 1))
      Score.create(:user_id => user_id, :value => record_score,:from_user_id => user_id)
      Score.create(:user_id => user_id, :value => -record_score,:from_user_id => user_id)
      Record.create(:user_id => user_id, :from_user_id => user_id, :beaconid=> beaconid, :game_id => game_id, :score => record_score, :allocation => record_allocation)
      return record_score
    else
      return "已经被抢光啦，发卡券吧"
    end
  end

  def self.share_allocation(user_id, openidshare , game_id, redpack)
    redpack_time = RedpackTime.find_by(:redpack_id =>redpack.id)
    person_num = redpack_time.person_num
    if openidshare
      au = Authentication.find_by_uid(openidshare)
      from_user_id = au.user_id 
      from_user = User.find from_user_id 
      user_allocation= UserAllocation.find_by("user_id = ? and allocation > ? and num > ?", from_user_id , 0, 0)
      if user_allocation == nil 
        render :status => 200, json: {'info' => "已经被抢光啦，发卡券吧"}
      end
      if user_allocation.num > 2
        record_allocation = rand((user_allocation.allocation/person_num/2)..(user_allocation.allocation/person_num*2))   
      elsif user_allocation.num = 1
        record_allocation = user_allocation.allocation
      end  
      record_score = rand((record_allocation/person_num/2)..(record_allocation/person_num*2))
      user_allocation.update(:user_id => from_user_id, :allocation => (user_allocation.allocation - record_allocation), :num => (user_allocation.num - 1))
      UserAllocation.create(:user_id => user_id, :allocation => (record_allocation -record_score)) 
      Score.create(:user_id => user_id, :value => record_score,:from_user_id => from_user_id)
      Record.create(:user_id => user_id, :from_user_id => from_user_id, :beaconid=> beaconid, :game_id => game_id, :score => record_score, :allocation => record_allocation)
    end
  end

  def self.bus_redpack(user_id, beaconid) 
    score = UserScore.find_by(user_id: user_id).total_score 
    Redpack.find_by(beaconid: beaconid).weixin_post(current_user, beaconid_url, score)
    Score.create(:user_id => current_user.id, :value => -score,:from_user_id => current_user.id)
  end 

  def self.x_random(min,max)
    return (rand((max-min) ** 2) ** (1.0/2)).to_i
  end

  def self.next_long(min,max)
    return rand(max-min+1) + min
  end

  def self.generate(total,count,max,min)

    $redis.del("hongbaolist")
    $redis.del("hongBaoConsumedMap")
    $redis.del("hongBaoConsumedList")

    result = Array.new(count)
    result_hongbao = Array.new(0)
    if total < min
      min = total
      result[0] = min
      result_hongbao = {:id => 0, :money => result[0]}
      $redis.lpush("hongbaolist",result_hongbao.to_json)
      #p $redis.lrange("hongbaolist",0,-1)
      return $redis.lrange("hongbaolist",0,-1)
    else
      average = total/count

      a = average - min
      b = max - average

      range1 = (average - min) ** 2
      range2 = (max - average) ** 2

      for i in 0..(result.length-1)
        if (next_long(min,max) > average)
          temp = min + x_random(min,average)
          result[i] = temp
          total -= temp
        else
          temp = max - x_random(average,max)
          result[i] = temp
          total -= temp
        end
      end

      while (total > 0)
        for i in 0..(result.length-1)

          if total > 0 && result[i] < max 
            result[i] += 1
            total -= 1
          end
        end
      end

      while (total < 0)
        for i in 0..(result.length-1)
          if total < 0 && result[i] > min
            result[i] -= 1
            total += 1
          end
        end
      end

      for i in 0..(result.length-1)
        result_hongbao = {:id => i, :money => result[i]}
        $redis.lpush("hongbaolist",result_hongbao.to_json)
      end
      p $redis.lrange("hongbaolist",0,-1)
      # return result
      return $redis.lrange("hongbaolist",0,-1)
    end
  end

  # def self.ge

  #   generate(500,2.5,600,150)
  # #   $redis.script(try_get_hongbao_script)
  # #    for i in 0..9
  # #   p $redis.eval(tryGetHongBaoScript, 4, "hongBaoList", "hongBaoConsumedList", "hongBaoConsumedMap", i); 
  # # end
  # end

  def self.test(user_id)
    if $redis.hexists("hongBaoConsumedMap" , user_id) == true 
      p $redis.hget("hongBaoConsumedMap",user_id)
      return nil
    else
      hongbao = $redis.rpop("hongbaolist")
      if hongbao
        hongbao = JSON.parse(hongbao)
        hongbao.merge!({:user_id => user_id})
        $redis.hset("hongBaoConsumedMap",user_id,user_id)
      #p $redis.hget("hongBaoConsumedMap",user_id)
      $redis.lpush("hongBaoConsumedList",hongbao.to_json)
      #p $redis.lrange("hongBaoConsumedList",0,-1)
      return hongbao 
    else
      return nil
    end

  end
end

def self.gain_seed_redpack(user_id, game_id,redpack,beaconid) 
    # hongbao =  Hash.new
    # if $redis.llen("hongbaolist") == 0
    #   for i in 0..(llen("hongBaoConsumedMap")-1)
    #     beaconid = Ibeacon.find_by(:url=>beaconid).id
    #     redpack_time = RedpackTime.where(:redpack_id =>redpack.id).order("start_time desc")[0]
    #     person_num = redpack_time.person_num
    #     user_allocaiton = UserAllocation.find_by(:user_id => hongbao["user_id"])
    #     if user_allocaiton 
    #       user_allocaiton.update( :allocation => (user_allocaiton.allocation + hongbao["money"]), :num => (person_num - 1))
    #     else
    #       UserAllocation.create(:user_id => hongbao["user_id"], :allocation => hongbao["money"], :num => (person_num - 1))
    #     end
    #     Score.create(:user_id => hongbao["user_id"], :value => hongbao["money"],:from_user_id => hongbao["user_id"])
    #     Record.create(:user_id => hongbao["user_id"], :from_user_id => hongbao["user_id"], :beaconid=> beaconid, :game_id => game_id, :score => hongbao["money"], :allocation => hongbao["money"])
    #     p "yongwanle"
    #   end 
    # end
    beaconid = Ibeacon.find_by(:url=>beaconid).id
    check = Check.find_by(user_id: user_id, beaconid: beaconid,state: 1,game_id: game_id)
      check.update(:state => 0) if check
      
    if $redis.hexists("hongBaoConsumedMap" , user_id) == true 
      #p $redis.hget("hongBaoConsumedMap",user_id)
      return 0 
    else
      hongbao = $redis.rpop("hongbaolist")
      if hongbao
        hongbao = JSON.parse(hongbao)
      #p hongbao
      hongbao.merge!({:user_id => user_id})
      #p $redis.lrange("hongbaolist",0,-1)
      $redis.hset("hongBaoConsumedMap",user_id,user_id)
      #p $redis.hget("hongBaoConsumedMap",user_id)
      $redis.lpush("hongBaoConsumedList",hongbao.to_json)
      #p $redis.lrange("hongBaoConsumedList",0,-1)
      


      user = User.find user_id
      user.incr_social(beaconid, 3)

      return hongbao["money"]
    else
      return 0
    end
  end
end

end
