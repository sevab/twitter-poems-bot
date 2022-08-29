defmodule Mix.Tasks.TweetBy do
  use Mix.Task

  # Tweet from @by_vershy
  def run(_) do
    ExTwitter.configure(
      consumer_key: System.get_env("POEM_CONSUMER_KEY"),
      consumer_secret: System.get_env("POEM_CONSUMER_SECRET"),
      access_token: System.get_env("POEM_ACCESS_TOKEN"),
      access_token_secret: System.get_env("POEM_ACCESS_TOKEN_SECRET")
    )

    PoemBot.tweet(db_name: "db/poems.db", hashtags: "#БелТві #ТвіБай")
    :ok
  end
end
