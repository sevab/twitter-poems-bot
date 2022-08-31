defmodule Mix.Tasks.TweetUkr do
  use Mix.Task

  # Tweet from @ukr_virsh
  def run(_) do
    Mix.Task.run("app.start")

    ExTwitter.configure(
      consumer_key: System.get_env("UA_POEM_CONSUMER_KEY"),
      consumer_secret: System.get_env("UA_POEM_CONSUMER_SECRET"),
      access_token: System.get_env("UA_POEM_ACCESS_TOKEN"),
      access_token_secret: System.get_env("UA_POEM_ACCESS_TOKEN_SECRET")
    )

    PoemBot.post(db_name: "db/ukr_poems.db", hashtags: "#УкрТві", telegram_channel: "@ukr_virsh")
    :ok
  end
end
