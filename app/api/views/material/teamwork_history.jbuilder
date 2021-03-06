if @exist_teamwork.present?
  if @exist_teamwork
    json.result 0
    json.is_goon @is_goon
    json.teamwork do
      json.id  @exist_teamwork.id
      json.total_work  @exist_teamwork.total_work
      json.state  @exist_teamwork.state
      json.sponsor @exist_teamwork.sponsor
      json.reward @material.team_reward
      # json.result_percent @teamwork.result_percent
      json.ower current_user.id
    end
    json.partner_users(@partner_users) do |item|
      json.id  item.id
      json.name item.name
      json.profile_img_url item.profile_img_url
      json.sex item.sex
      json.city item.city
      json.expect_percent @exist_teamwork.get_user_percent(item.id)
      json.result_percent @exist_teamwork.get_result_percent(item.id)
    end

    json.ower do
      json.id  @ower.id
      json.name @ower.name
      json.profile_img_url @ower.profile_img_url
      json.sex @ower.sex
      json.city @ower.city
      json.expect_percent @exist_teamwork.get_user_percent(@ower.id)
      json.result_percent @exist_teamwork.get_result_percent(@ower.id)
    end

  else
    json.result -1
  end

else
  json.result -1
end
