defmodule ScoreBreak.Application do
  @moduledoc false
  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid(), any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      ScoreBreak.Persistence.Repo
    ]

    opts = [strategy: :one_for_one, name: ScoreBreak.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
