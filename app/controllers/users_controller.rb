class UsersController < AuthenticatedController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :ensure_user_paid!

  before_action :set_user

  def new
    if current_user.present? && !current_user.guest?
      redirect_to dashboard_path
    end
    @registration = Registration.new
  end

  def create
    valid_params  = params[:google_id_token].present? ? params : registration_params
    @registration = Registration.new(valid_params, current_user || User.new)

    if @registration.save
      login(@registration.user)
      redirect_to welcome_path
    else
      flash[:error] = @registration.errors.full_messages.join(', ')
      redirect_to new_user_path
    end
  end

  def edit
    gon.stripe_public_key = ENV['STRIPE_PUBLIC_KEY']
    if @user.stripe_customer
      @existing_card = current_user.stripe_customer.sources.first
    end
  end

  def update
    if params[:user][:google_id]
      google_identity = GoogleSignIn::Identity.new(params[:user][:google_id])
      google_id = google_identity.user_id
      params[:user][:google_id] = google_id
    end

    @user.assign_attributes(user_params)
    @user.skip_password_validation = true

    valid = @user.save && add_card_to_user

    if valid
      RefreshStripeCacheJob.perform_later(@user.id)
      flash[:success] = 'Settings updated'
      redirect_to dashboard_path
    else
      flash[:error] = @user.errors.full_messages.join(', ')
      redirect_to settings_path
    end
  end

  def destroy
    @payment_service = PaymentService.new(stripe_subscription_id: @user.stripe_subscription_id)

    if @payment_service.cancel_subscription && @user.destroy
      flash[:success] = 'Account deleted. Sorry to see you go!'
      redirect_to new_user_path
    else
      flash[:error] = 'Something went wrong.'
      redirect_to settings_path
    end
  end

  def cancel_subscription
    @payment_service = PaymentService.new(stripe_subscription_id: @user.stripe_subscription_id)

    if @payment_service.cancel_subscription
      @user.update(stripe_subscription_id: nil)
      flash[:success] = 'Subscription cancelled.'
    else
      flash[:error] = 'Something went wrong.'
    end

    redirect_to settings_path
  end

  private

  def add_card_to_user
    @payment_service = PaymentService.new({ stripe_customer_id: @user.stripe_customer_id })

    if params[:stripeToken]
      @payment_service.add_card_to_customer(token: params[:stripeToken])
    else
      true
    end
  end

  def set_user
    @user = current_user
  end

  def registration_params
    params.require(:registration).permit(
      :name,
      :email,
      :phone,
      :email_reminders,
      :sms_reminders,
      :track_weekends,
      :password,
      :google_id
    )
  end

  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :phone,
      :email_reminders,
      :sms_reminders,
      :track_weekends,
      :password,
      :google_id
    )
  end
end
