defmodule Discuss.User do
  use Discuss.Web, :model

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :provider, :string
    field :token, :string
    field :is_admin, :boolean, default: false
    has_many :posts, Discuss.Post
    has_many :topics, Discuss.Topic
    has_many :comments, Discuss.Comment

    timestamps()
  end

  def changelogin(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :username, :password])
    |> validate_required([:email, :username, :password])
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :token])
    |> validate_required([:email, :token])
  end

end
