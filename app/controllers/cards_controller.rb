class CardsController < ApplicationController
  require "payjp"
  before_action :set_card

  def index #CardのデータをPayjpに送って情報を取り出す
    if @card.present?
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @card_information = customer.cards.retrieve(@card.card_id)

      # 登録しているカード会社のブランドアイコンを表示する
      @card_brand = @card_information.brand
      case @card_brand
        when "Visa"
          @card_src = "visa.svg"
        when "JCB"
          @card_src = "jcb.svg"
        when "MasterCard"
          @card_src = "mastercard.svg"
        when "American Express"
          @card_src = "american-express.svg"
        when "Diners Club"
          @card_src = "diners-club.svg"
        when "Discover"
          @card_src = "discover.svg"
      end
    end
  end

  def new
    card = Card.where(user_id: current_user.id)
    redirect_to action: "index" if card.exists?
  end

  def create
    Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]

    if params['payjp-token'].blank?
      redirect_to action: "new"
    else
      customer = Payjp::Customer.create(
      description: '登録テスト',
      email: current_user.email,
      card: params['payjp-token'],
      metadata: {user_id: current_user.id}
      )
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      if @card.save
        redirect_to action: "index"
      else
        redirect_to action: "create"
      end
    end
  end

  def destroy #PayjpとCardのデータベースを削除
    Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
    customer = Payjp::Customer.retrieve(@card.customer_id)
    customer.delete
    if @card.destroy #削除に成功した時にポップアップを表示
      redirect_to action: "index", notice: "削除しました"
    else #削除に失敗した時にアラートを表示
      redirect_to action: "index", alert: "削除できませんでした"
    end
  end

  private

  def set_card
    @card = Card.where(user_id: current_user.id).first if Card.where(user_id: current_user.id).present?
  end

end
