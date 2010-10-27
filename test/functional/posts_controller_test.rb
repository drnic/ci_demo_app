require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  test "index" do
    get :index
    assert_match(/Posts/, response.body)
  end
end
