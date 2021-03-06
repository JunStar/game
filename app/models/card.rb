class Card < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :wx_authorizer
  belongs_to :party
  has_many :records
  has_many :card_options
  belongs_to :ibeacon

  has_many :card_appearance

  def self.get_types_for_select
    [["优惠券", 0], ["折扣券", 1], ["代金券", 2], ["礼品券", 3], ["团购券", 4], ["现金红包", 5] ] 
  end


  def beacon_name
    if self.beaconid
      b = Ibeacon.find self.beaconid
      return b.name if b
    end
  end

  def cloning(recursive=false)
    Card.create self.attributes.except!("created_at", "id")
  end

  def get_store(tid=nil)
    cond = "1=1"
    cond = "group_id=#{tid}" if tid
    cos = self.card_options.where( cond )
    cos.sum{|co|co.store}
  end

  def lottery(tid, uid, gid, bid)
    cond = "1=1"
    cond = "group_id=#{tid}" if tid
    card_options = self.card_options.where( cond )
    total = card_options.sum{|c|c.store}
    n = rand(total)
    
    range = 0
    card_options.each do |co|
      range += co.store
      if n < range
        Record.create(:user_id => uid, :game_id =>gid, :beaconid => bid, :score => co.id, :remark => co.title, :object_type => 'Card', :object_id => self.id)
        co.store -= 1
        co.save
        if co.group_id == 5
          co.send_redpack(uid, gid, bid)
        end
        return co
      end
    end   
  end 

end
