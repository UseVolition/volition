class Registration
  include ActiveModel::Model
  include ApplicationHelper

  attr_accessor *%i(
    name
    email
    password
    user
    params
  )

  delegate :errors, to: :user

  def initialize(params = {}, user = User.new)
    @params = params
    @user   = user
  end

  def save
    referral_code = @params.delete(:referral_code)

    if signing_up_with_google?
      @user.skip_password_validation = true
      google_identity = GoogleSignIn::Identity.new(params[:google_id_token])
      google_id = google_identity.user_id
      email = google_identity.email_address
      name = google_identity.name

      @user.assign_attributes({
        name: name,
        email: email,
        google_id: google_id
      })
    else
      @user.assign_attributes(params)
    end

    @user.guest = false
    @user.timezone = Time.zone.tzinfo.name

    add_to_mailchimp_newsletter
    note_referral(referral_code)
    @user.save
  end

  private

  def note_referral(referral_code)
    referrer = User.find_by(referral_code: referral_code)
    return unless referrer
    @user.referred_by = referrer.id
  end

  def add_to_mailchimp_newsletter
    return nil if self_hosted? || @user.guest? || Rails.env.development? || Rails.env.test?

    begin
      gibbon = Gibbon::Request.new(api_key: ENV["MAILCHIMP_API_KEY"])
      gibbon.lists(ENV["MAILCHIMP_LIST_ID"]).members.create(
        body: {
          email_address: @user.email,
          status: "subscribed"
        }
      )
    rescue Gibbon::MailChimpError => e
      puts e
    end
  end

  def signing_up_with_google?
    params[:google_id_token].present?
  end
end
