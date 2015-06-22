class Teamwork < ActiveRecord::Base
  belongs_to :material

  validates :sponsor,
            :presence => true

  validates :total_work,
            :presence => true

  validates :material_id,
            :presence => true


  def self.create_teamwork(user_id, material_id, init_percents, total_work = 1000)
    t = Teamwork.new
    t.sponsor = user_id
    t.material_id = material_id
    t.total_work = total_work
    if init_percents
      t.team_percent = init_percents.join(',')
      rp = []
      for i in 0...init_percents.count
        rp.push 0
      end
      t.result_percent = rp.join(',')
    end
    if t.save
      return t
    else

    end
  end

  #0 代表进行中  1代表成功完成  2代表失败结束
  def teamwork_state
    [0, 1, 2]
  end

  before_create :begin_teamwork

  def begin_teamwork
    self.state = teamwork_state[0]
    if self.partner.nil?
      # self.partner = self.sponsor.to_s
      add_partner self.sponsor
    end

  end


  def add_one_person(user_id, percent, appid=WX_APPID)
    if user_id && percent
      add_partner user_id
      add_percent percent
      save
    end
  end

  def partners
    if self.partner
      self.partner.split(',')
    else
      []
    end
  end

  def partner_users
    arr = partners
    arr1 = []
    arr.each do |item|
      u = User.find_by_id(item.to_i)
      arr1.push u
    end
    arr1
  end


  def add_partner (user_id, appid = WX_APPID)
    if user_id
      arr = partners
      arr.push user_id.to_s

      self.partner = arr.join(',')
    end
  end

  def team_percents
    if self.team_percent != nil
      self.team_percent.split(',')
    else
      []
    end
  end

  def add_percent(percent)
    if percent && percent < 1.0
      arr = team_percents
      arr.push percent
      arr.join(',')
      self.team_percent = arr.join(',')
    end
  end

  def get_user_percent(user_id)
    arr1 = partners
    arr2 = team_percents
    for i in 0...(arr1.count)
      item = arr1[i]
      if item.to_s == user_id.to_s
          return arr2[i]
      end
    end

  end

  # 剩余的 percent
  def rest_percent
    arr = team_percents
    if arr.count > 0
      total = 0.0
      arr.each {|item| total += item.to_f}
      if total > 1.0
        0.0
      else
        1.0 - total
      end
    else
      1.0
    end

  end

  def results
    if self.result_percent
      self.result_percent.split(',')
    else
      []
    end
  end

  def results_sum
    arr = results
    sum = 0.0
    arr.each { |item| sum += item.to_f }
    sum
  end


  def set_result_percent(user_id,percent)
    if user_id
      p "user_id = #{user_id} and partners = #{partners}"
      index = partners.index user_id.to_s
      r = results
      p "results = #{r} and index = #{index}"
      if r
        r[index] = percent
        self.result_percent = r.join(',')
        [index,percent]
      end
    end
  end


  def rand_result_percent(user_id,num,is_sponsor = false)
    p =  self.probability
    up = (get_user_percent(user_id)).to_f
    interval = (1.0 / self.team_persons * 0.9)
    min = up - up * interval
    max = up + up * interval
    num = 1000 - rand(100) if num < 1000
    num = 2000 + rand(100) if num > 2000
    p = p + (p * num).to_f / 2000.0 * 0.1
    if is_sponsor
      return Tool.get_rand_num(min,max,p + 0.2)
    end
    return Tool.get_rand_num(min,max,p)
  end



  def get_result_percent(user_id)
    if user_id
      index = partners.index user_id.to_s
      p "partners = #{partners}  and index = #{index}"
      r = results
      if r && index
        r[index]
      end
    end
  end



  def is_successful?
    self.state == teamwork_state[1]
  end

  def is_failure?
    self.state == teamwork_state[2]
  end

  def is_over?
    is_successful? || is_failure?
  end

  def is_runing?
    self.state == teamwork_state[0]
  end

end