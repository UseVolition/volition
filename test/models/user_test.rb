require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:garrett)
    StripeMock.start
    @stripe_helper = StripeMock.create_test_helper
    @stripe_helper.create_plan(id: 'basic', amount: 100)
    @customer = Stripe::Customer.create(source: @stripe_helper.generate_card_token)
    @subscription = Stripe::Subscription.create(plan: 'basic', customer: @customer)
  end

  teardown do
    StripeMock.stop
  end

  test '#had_a_great_day? returns false' do
    reflection = Reflection.create(
      rating: 6,
      wrong: 'Took too many breaks today.',
      right: 'Finished most of my tasks.',
      undone: 'Some things.',
      date: Date.current,
      user: @user
    )

    assert(@user.had_a_great_day? == false)
  end

  test '#had_a_great_day? returns true' do
    reflection = Reflection.create(
      rating: 10,
      wrong: 'Nothing!',
      right: 'Finished all of my tasks.',
      undone: 'Nothing.',
      date: Date.current,
      user: @user
    )

    assert(@user.had_a_great_day? == true)
  end

  test '#recently_signed_up? returns false' do
    travel_to(1.day.from_now) do
      assert(@user.recently_signed_up? == false)
    end
  end

  test '#recently_signed_up? returns true' do
    assert(@user.recently_signed_up? == true)
  end

  test '.want_sms_reminders' do
    @user.update(sms_reminders: true, phone: '9144825484')
    new_user = User.create(
      email: 'new@example.com',
      password: 'password',
      password_confirmation: 'password'
    )

    assert_includes(User.want_sms_reminders, @user)
    refute_includes(User.want_sms_reminders, new_user)
  end

  test '.want_email_reminders' do
    @user.update(email_reminders: true)
    new_user = User.create(
      email: 'new@example.com',
      password: 'password',
      password_confirmation: 'password'
    )

    assert_includes(User.want_email_reminders, @user)
    refute_includes(User.want_email_reminders, new_user)
  end

  test '.finishing_their_day' do
    chicago_time_zone = ActiveSupport::TimeZone.all.find {|zone| zone.tzinfo.name == 'America/Chicago'}


    @user.update(timezone: 'America/Chicago')

    new_user = User.create(
      email: 'new@example.com',
      password: 'password',
      password_confirmation: 'password',
      timezone: 'America/New_York'
    )

    travel_to(Time.utc(2016, 11, 10, 23, 0, 0)) do
      assert_includes(User.finishing_their_day, @user)
      refute_includes(User.finishing_their_day, new_user)
    end
  end

  test 'validation phone number is present when sms_reminders is true' do
    @user.sms_reminders = true

    @user.save

    assert_not_nil(@user.errors.full_messages)
  end

  test '#trialing?' do
    assert(@user.trialing?)

    Timecop.travel(Date.current+30) do
      refute(@user.trialing?)
    end
  end

  test '#trial_days_left' do
    assert_equal(30, @user.trial_days_left)

    Timecop.travel(Date.current+15) do
      assert_equal(15, @user.trial_days_left)
    end

    Timecop.travel(Date.current+30) do
      assert_equal(0, @user.trial_days_left)
    end

    Timecop.travel(Date.current+40) do
      assert_equal(0, @user.trial_days_left)
    end
  end
end
