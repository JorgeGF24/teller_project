defmodule GenericAppBackendTest.Router do
    use ExUnit.Case, async: true

    use Plug.Test

    @opts GenericAppBackend.Router.init([])

    # Test the endpoints

    test "return ok" do
        conn = conn(:get, "/")

        conn = GenericAppBackend.Router.call(conn, @opts)

        assert conn.state == :sent
        assert conn.status == 200
        assert conn.resp_body == "OK"
    end

    test "return Not found error" do
        conn = conn(:get, "/unicorn")

        conn = GenericAppBackend.Router.call(conn, @opts)

        assert conn.state == :sent
        assert conn.status == 404
        assert conn.resp_body == "Not Found"

    end

    test "create user succeeds" do
        conn = new_user("testUnique", "testUnique", "test")

        assert conn.state == :sent
        assert conn.status == 200

        # Duplicate user
        conn = new_user("testUnique", "testUnique", "test")

        assert conn.state == :sent
        assert conn.status == 403
    end

    test "create user error" do
        # Underscore in name
        conn = new_user("_test", "test", "test")

        assert conn.state == :sent
        assert conn.status == 400

        # No surname provided
        conn = conn(:put, "/new_user", %{"first_name" => "test", "password" => "test"})
        conn = GenericAppBackend.Router.call(conn, @opts)

        assert conn.state == :sent
        assert conn.status == 400
    end

    test "good login" do
        new_user("test", "test", "test")

        conn = login("test_test", "test")

        assert conn.state == :sent
        assert conn.status == 200
    end

    test "bad login" do
        new_user("test", "test", "test")

        # Wrong password
        conn = login("test_test", "t3st")

        assert conn.state == :sent
        assert conn.status == 403

        # Bad request (no password provided)
        conn = conn(:post, "/login", %{"username" => "test_test"})
        conn = GenericAppBackend.Router.call(conn, @opts)

        assert conn.state == :sent
        assert conn.status == 400
    end

    test "get user data" do
        new_user("test", "test", "test")
        conn = login("test_test", "test")

        
    end

    def new_user(first_name, last_name, password) do 
        conn(:put, "/new_user", %{"first_name" => first_name, "last_name" => first_name, "password" => first_name}) |>
            GenericAppBackend.Router.call(@opts)
    end

    def login(username, password) do
        conn(:post, "/login", %{"username" => username, "password" => password}) |>
            GenericAppBackend.Router.call(@opts)
    end

end
