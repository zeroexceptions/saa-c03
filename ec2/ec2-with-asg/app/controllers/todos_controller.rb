class TodosController < ApplicationController
  PAGE_SIZE = 50

  before_action :set_todo, only: %i[edit update destroy toggle]

  def index
    @todo = Todo.new
    load_list
  end

  def create
    @todo = Todo.new(todo_params)
    if @todo.save
      redirect_to root_path, notice: "Task added to your list."
    else
      load_list
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @todo.update(todo_params)
      redirect_to root_path, notice: "Your task has been updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy
    redirect_to root_path, notice: "Task deleted."
  end

  def toggle
    @todo.update!(completed: !@todo.completed)
    redirect_to root_path, notice: @todo.completed? ? "Nice work — task completed!" : "Task moved back to your list."
  end

  private

  def load_list
    counts = Rails.cache.fetch("todos/dashboard-counts/v1", expires_in: 10.seconds,
      race_condition_ttl: 2.seconds) { Todo.group(:completed).count }
    @active_count = counts.fetch(false, 0)
    @completed_count = counts.fetch(true, 0)
    @filter = params[:filter].presence_in(%w[all active completed]) || "all"
    @page = [params[:page].to_s.to_i, 1].max
    todos = Todo.order(completed: :asc, due_date: :asc, created_at: :desc, id: :desc)
    todos = todos.incomplete if @filter == "active"
    todos = todos.complete if @filter == "completed"
    # One extra row determines whether Next is needed without a COUNT query.
    @todos = todos.limit(PAGE_SIZE + 1).offset((@page - 1) * PAGE_SIZE).to_a
    @has_next_page = @todos.length > PAGE_SIZE
    @todos = @todos.first(PAGE_SIZE)
  end

  def set_todo
    @todo = Todo.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :details, :due_date)
  end
end
