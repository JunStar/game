class WxAuthorizer < ActiveRecord::Base
  validates_presence_of(:authorizer_appid,:component_appid,:message => "不能为空!")
  validates_uniqueness_of(:authorizer_appid,:message => "authorizer_id 不唯一!")

  has_many :qrcodes

end
