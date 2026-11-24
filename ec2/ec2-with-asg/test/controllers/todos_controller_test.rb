require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    Todo.delete_all
    now = Time.current
    Todo.insert_all!(Array.new(55) do |i|
      { title: "Task #{i}", completed: false, created_at: now, updated_at: now }
    end)
  end

  test "pages have bounded size and stable ordering for tied timestamps" do
    get root_path
    assert_response :success
    assert_select ".todo-card", count: 50
    assert_select ".pagination a", text: "Next →"
    first_page = css_select(".todo-title").map(&:text)

    get root_path(page: 2)
    assert_response :success
    assert_select ".todo-card", count: 5
    assert_select ".pagination a", text: "Next →", count: 0
    assert_empty first_page & css_select(".todo-title").map(&:text)
  end

  test "pagination preserves the completed filter" do
    Todo.update_all(completed: true)
    Todo.create!(title: "Active task")
    get root_path(filter: "completed")
    assert_select ".todo-card", count: 50
    assert_select ".todo-title", text: "Active task", count: 0
    assert_select ".pagination a[href=?]", root_path(filter: "completed", page: 2)
  end

  test "invalid page starts at page one and invalid create stays bounded" do
    get root_path(page: -1)
    assert_response :success
    assert_select ".todo-card", count: 50
    post todos_path, params: { todo: { title: "" } }
    assert_response :unprocessable_entity
    assert_select ".todo-card", count: 50
    assert_select ".errors"
  end

  test "dashboard counts are reused until the short cache expires" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    get root_path
    assert_select ".progress-foot", text: /55 left to go/
    Todo.create!(title: "New task")
    get root_path
    assert_select ".progress-foot", text: /55 left to go/
    travel 15.seconds do
      get root_path
      assert_select ".progress-foot", text: /56 left to go/
    end
  ensure
    Rails.cache = original_cache
  end
end
