class TodosController < ApplicationController
  before_action :set_todo, only: %i[edit update destroy toggle]

  def index
    @todo = Todo.new
    @counts = Todo.group(:completed).count
    @active_count = @counts.fetch(false, 0)
    @completed_count = @counts.fetch(true, 0)
    @filter = params[:filter].presence_in(%w[all active completed]) || "all"
    @todos = Todo.order(completed: :asc, due_date: :asc, created_at: :desc)
    @todos = @todos.incomplete if @filter == "active"
    @todos = @todos.complete if @filter == "completed"
    @todos = @todos.to_a
  end

  def create
    @todo = Todo.new(todo_params)
    if @todo.save
      redirect_to root_path, notice: "Task added to your list."
    else
      @counts = Todo.group(:completed).count
      @active_count = @counts.fetch(false, 0)
      @completed_count = @counts.fetch(true, 0)
      @filter = "all"
      @todos = Todo.order(completed: :asc, due_date: :asc, created_at: :desc).to_a
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

  def set_todo
    @todo = Todo.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :details, :due_date)
  end
end
