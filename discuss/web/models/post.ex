defmodule Discuss.Post do
  use Discuss.Web, :model

  schema "posts" do
    field :title, :string
    field :body, :string
    belongs_to :users, Discuss.Users, foreign_key: :users_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body])
    |> assoc_constraint(:user)
  end
end
