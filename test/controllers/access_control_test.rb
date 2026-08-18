require "test_helper"

class AccessControlTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one) # role: admin
    @user = users(:two)  # role: user
  end

  test "guests can see the product page" do
    get root_path
    assert_response :success
  end

  test "guests cannot open the chat" do
    get queries_path
    assert_redirected_to new_session_path
  end

  test "guests cannot open admin pages" do
    get dashboard_path
    assert_redirected_to new_session_path

    get documents_path
    assert_redirected_to new_session_path

    get admin_providers_path
    assert_redirected_to new_session_path
  end

  test "regular users see the product page but not admin pages" do
    sign_in_as @user

    get root_path
    assert_response :success

    get dashboard_path
    assert_redirected_to root_path

    get documents_path
    assert_redirected_to root_path

    get admin_providers_path
    assert_redirected_to root_path

    get users_path
    assert_redirected_to root_path
  end

  test "regular users can open the chat" do
    sign_in_as @user

    get queries_path
    assert_response :success
  end

  test "admins can open everything" do
    sign_in_as @admin

    get dashboard_path
    assert_response :success

    get documents_path
    assert_response :success

    get admin_providers_path
    assert_response :success

    get users_path
    assert_response :success

    get queries_path
    assert_response :success
  end

  test "regular users cannot assign roles" do
    sign_in_as @user

    patch user_path(@admin), params: { user: { role: "user" } }
    assert_redirected_to root_path
    assert @admin.reload.admin?, "role must be unchanged"
  end

  test "admins can assign roles" do
    sign_in_as @admin

    patch user_path(@user), params: { user: { role: "admin" } }
    assert_redirected_to users_path
    assert @user.reload.admin?
  end

  test "admins cannot change their own role" do
    sign_in_as @admin

    patch user_path(@admin), params: { user: { role: "user" } }
    assert_redirected_to users_path
    assert @admin.reload.admin?, "own role must stay admin"
  end

  test "queries are scoped to their owner" do
    sign_in_as @user

    post queries_path, params: { question: "hello?" }
    assert_response :success

    other = Query.last
    assert_equal @user.id, other.user_id

    # another user cannot stream someone else's query
    sign_out
    sign_in_as @admin
    get queries_path
    assert_response :success
    assert_not_includes response.body, "hello?"
  end

  test "users can clear only their own chat history" do
    sign_in_as @user
    mine = Query.create!(question: "mine", user: @user, status: "completed", answer: "x")
    theirs = Query.create!(question: "theirs", user: @admin, status: "completed", answer: "x")

    delete clear_queries_path
    assert_redirected_to queries_path
    assert_nil Query.find_by(id: mine.id)
    assert Query.exists?(theirs.id)
  end

  test "guests cannot clear chat history" do
    delete clear_queries_path
    assert_redirected_to new_session_path
  end
end
