class Admin::MaterialsController < Admin::BaseController
  before_filter :clear_rubbish, only: [:update,:destroy]
  def index
    cond = "1=1"
    cond += " and category_id=#{params[:cid]}" if params[:cid]
    cond += " and name like '%#{params[:q]}%'" if params[:q]
    cond += " and rrr=#{params[:rrr]}" if params[:rrr]
    #@materials = Material.includes(:category).where(cond).order('rrr desc, id desc').page(params[:page])
  
    @materials = Material.includes(:category).where(cond).order('id desc').page(params[:page])
  end

  def recommend_to_qq
    material = Material.find(params[:id])
    material.is_qq = 1
    material.save
    redirect_to :back
  end

  def recommend_game
    material = Material.find(params[:id])
    material.is_recommend_to_qq = 1
    material.save
    redirect_to :back
  end

  def new
    @material = Material.new
  end

  def create
    if material_params[:link].blank?
      material = Material.new material_params
      material.save
    else
      material = Material.create_by_web(material_params[:link])
    end
    redirect_to [:admin,:materials]
  end

  def edit
    @material = Material.find_by_url params[:id]
    @material = Material.find params[:id] unless @material
  end

  def update
    if material_params[:link].blank?
      @material.update_attributes material_params
    else
      @material = Material.create_by_web(material_params[:link])
    end

    clear_page(@material)

    redirect_to [:admin,:materials]
  end

  def update_state
    material = Material.find params[:id]
    material.invert_state 
    render json: {msg: 'ok', val: material.reload.cn_state}
  end

  def update_rrr
    material = Material.find params[:id]
    material.invert_rrr
    render json: {msg: 'ok', val: material.reload.cn_rrr}
  end

  

  def clone
    material = Material.find params[:id]
    material.cloning(true)
    redirect_to [:admin,:materials]
  end

  def wx_clone
    material = Material.find params[:id]
    material.wx_cloning(true)
    redirect_to [:admin,:materials]
  end

  def destroy
    @material.destroy
    render nothing: true
  end


  def get_objects
    cond = '1=1'
    cond = "beaconid=#{beaconid}" if params[:beaconid]
    @objects =  params[:object_type].capitalize.constantize.where(cond).order('created_at desc').limit(20)

    render :partial => "objects"
  end

private  
  def material_params
    params.require(:material).permit(:link,:object_type, :object_id, :name,:description,:category_id,:wx_appid,:wxdesc,:wx_tlimg,:pyq_url,:thumb,:wx_url,:share_url, :wx_title, :wx_ln, :advertisement, :advertisement_1,:team_persons,:one_percent,:team_reward,:total_work,:probability)
  end

  def clear_rubbish
    @material = Material.find params[:id]
    clear_page(@material)
  end

end
