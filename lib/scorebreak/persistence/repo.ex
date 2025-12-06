defmodule ScoreBreak.Persistence.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :scorebreak,
    adapter: Ecto.Adapters.Postgres

  @spec listen(String.t()) :: {:ok, pid(), reference()}
  def listen(channel) do
    with {:ok, pid} <- Postgrex.Notifications.start_link(__MODULE__.config()),
         {:ok, ref} <- Postgrex.Notifications.listen(pid, channel) do
      {:ok, pid, ref}
    end
  end
end
