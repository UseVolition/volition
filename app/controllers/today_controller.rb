class TodayController < ApplicationController
  before_action :set_user
  before_action :verify_that_today_is_trackable

  def show
    @week_plan = current_week_plan
    @todo_list = TodoList.today(@user)
    @button_text, @button_path = if Reflection.today(current_user).present?
                                   ["Plan for tomorrow", tomorrow_path]
                                 else
                                   ["Reflect on your day", reflect_path]
                                 end

    if @todo_list.blank?
      redirect_to new_today_path
    else
      @todos = @todo_list.todos.frontend_info
    end
  end

  def new
    if TodoList.today(@user)
      redirect_to today_path
    end

    @week_plan = current_week_plan
    @todo_list = TodoList.new
    5.times do
      @todo_list.todos.build
    end
  end

  def create
    @todo_list = TodoList.new(
      date: Date.current,
      user: @user,
      list_type: 'daily',
      week_plan: current_week_plan
    )

    if @todo_list.save
      @todo_list.update(todos_attributes: todo_list_params[:todos_attributes])
      redirect_to today_path
    end

  end

  private

  def set_user
    if params[:guest].present?
      @user = User.create!(guest: true, password: SecureRandom.hex)
      login(@user)
    elsif current_user
      @user = current_user
    else
      redirect_to login_path
    end
  end

  def todo_list_params
    params.require(:todo_list).permit(todos_attributes: [:content, :estimated_time_blocks])
  end
end
