class Admin::BgamesController < Admin::BaseController
  before_action :set_bgame, only: [:show, :edit, :update, :destroy]

  State = [["下线", 0], ["上线", 1]]

  respond_to :html

  def index
    cond = "1=1"
    cond += " and beaconid=#{params[:beaconid]}" if params[:beaconid]
    cond += " and game_id=#{params[:game_id]}" if params[:game_id]
    limit = 20
    limit = params[:limit].to_i if params[:limit]
    @bgames = Bgame.where(cond).order('created_at desc').page(params[:page]).per(limit)
  end

  def show
    respond_with(@bgame)
  end

  def new
    if params[:material_id]
      @game = Material.find params[:material_id]
      @bgame = @game.bgames.new
    else
      @bgame = Bgame.new
    end
    respond_with(@bgame)
  end

  def edit
    if params[:material_id]
      @game = Material.find params[:material_id]
    end
  end

  def create
    @bgame = Bgame.new(bgame_params)
    @bgame.save
    redirect_to [:admin, :bgames]
  end

  def update
    @bgame.update(bgame_params)
    redirect_to [:admin, :bgames]
  end

  def destroy
    @bgame.destroy
    redirect_to [:admin, :bgames]
  end

  def clone
    bgame = Bgame.find params[:id]
    bgame.cloning(true)
    redirect_to [:admin,:bgames]
  end


  private
    def set_bgame
      @bgame = Bgame.find(params[:id])
    end

    def bgame_params
      params.require(:bgame).permit(:beaconid, :game_id, :state, :remark)
    end
end
