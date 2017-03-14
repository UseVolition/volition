class DashboardController < AuthenticatedController
  def show
    @tomorrows_todo_list = TodoList.includes(:todos).tomorrow(current_user)
    @todays_todo_list = TodoList.includes(:todos).today(current_user)
    @past_todo_lists = TodoList.includes(:todos).past(current_user).paginate(page: params[:page])
  end
end
