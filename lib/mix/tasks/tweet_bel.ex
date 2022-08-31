defmodule Mix.Tasks.TweetBel do
  use Mix.Task

  # Tweet from @by_vershy
  def run(_) do
    Mix.Task.run("app.start")

    ExTwitter.configure(
      consumer_key: System.get_env("BY_POEM_CONSUMER_KEY"),
      consumer_secret: System.get_env("BY_POEM_CONSUMER_SECRET"),
      access_token: System.get_env("BY_POEM_ACCESS_TOKEN"),
      access_token_secret: System.get_env("BY_POEM_ACCESS_TOKEN_SECRET")
    )

    PoemBot.post(db_name: "db/bel_poems.db", hashtags: "#БелТві #ТвіБай", telegram_channel: "@versh_by")
    :ok
  end
end
