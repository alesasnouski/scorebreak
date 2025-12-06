import Config
import Dotenvy

## Load dotenv files
source!(["config/.env.#{config_env()}", "config/.env.secret.#{config_env()}", System.get_env()])

pg_user = env!("POSTGRES_USER", :string, "postgres")
pg_pass = env!("POSTGRES_PASSWORD", :string!)
pg_host = env!("POSTGRES_HOST", :string, "localhost")
pg_port = env!("POSTGRES_PORT", :string, "5432")
pg_pool = env!("POSTGRES_POOL", :atom, DBConnection.ConnectionPool)
pg_database = env!("POSTGRES_DB", :string!)
pg_pool_size = env!("POSTGRES_POOL_SIZE", :integer!, 10)

config :scorebreak, ScoreBreak.Persistence.Repo,
  username: pg_user,
  password: pg_pass,
  hostname: pg_host,
  database: pg_database,
  port: pg_port,
  pool: pg_pool,
  pool_size: pg_pool_size,
  show_sensitive_data_on_connection_error: false,
  types: ScoreBreak.PostgresTypes
