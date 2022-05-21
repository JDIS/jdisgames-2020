defmodule DiepIO.UsersRepositoryTest do
  use DiepIO.DataCase, async: true

  alias DiepIO.UsersRepository

  describe "users" do
    alias DiepIOSchemas.User

    @valid_attrs %{name: "some name"}
    @invalid_attrs %{name: nil, secret_key: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> UsersRepository.create_user()

      user
    end

    @tag :database
    test "get_user_id_from_secret/1 returns a tuple with ok and id of the user" do
      user = user_fixture()
      assert UsersRepository.get_user_id_from_secret(user.secret_key) == {:ok, user.id}
    end

    @tag :database
    test "get_user_id_from_secret/1 with a bad secret returns a tuple with error" do
      assert {:error, _} =
               UsersRepository.get_user_id_from_secret("some secret that doesnt exist")
    end

    @tag :database
    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = UsersRepository.create_user(@valid_attrs)
      assert {:ok, user.name} == Map.fetch(@valid_attrs, :name)
      assert String.length(user.secret_key) == 36
    end

    @tag :database
    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UsersRepository.create_user(@invalid_attrs)
    end

    @tag :database
    test "create_user/1 enforce an unique name contraint" do
      UsersRepository.create_user(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = UsersRepository.create_user(@valid_attrs)
    end
  end
end
