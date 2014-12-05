class Domain < ActiveRecord::Base
  def pv
    k = "domain_#{self.id}"
    $redis.get(k)
  end

  def get_name
    tags = ['weixin', 'ifeng', 'jd', 'apple', 'sogou']
    tag = tags.sample(1)[0]
    self.name.gsub("*", rand(1000).to_s )
    #self.name.gsub("*", "mp.weixin.qq.com")
  end
end
