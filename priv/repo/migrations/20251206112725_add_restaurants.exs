defmodule ScoreBreak.Persistence.Repo.Migrations.AddRestaurants do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION ltree")

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :first_name, :string
      add :last_name, :string

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create table(:places, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :name, :string
      add :path, :ltree

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create index(:places, [:path], using: :gist)

    create table(:user_places, primary_key: false) do
      add :user_id, references(:users, type: :binary_id), primary_key: true, null: false
      add :place_id, references(:places, type: :binary_id), primary_key: true, null: false
      add :access, :integer

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create table(:restaurants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :place_id, references(:places, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create index(:restaurants, [:place_id])
  end

  def down do
    execute("DROP TABLE user_places")
    execute("DROP TABLE users")
    execute("DROP TABLE restaurants")
    execute("DROP TABLE places")
    execute("DROP EXTENSION ltree")
  end
end
