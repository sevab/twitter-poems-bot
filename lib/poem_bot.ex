defmodule PoemBot do
  import DbHelpers

  def post(db_name: db_name, hashtags: hashtags, telegram_channel: telegram_channel) do
    {:ok, conn} = Exqlite.Sqlite3.open(db_name)

    poem = get_random_poem!(conn)
    author = get_author_by_id!(conn, poem.author_id)

    prepare_poem_text(
      poem: poem,
      author: author,
      hashtags: hashtags
    )
    |> split_text_into_threads()
    |> tweet_a_thread()

    prepare_poem_text(
      poem: poem,
      author: author,
      hashtags: nil
    )
    |> post_to_telegram(telegram_channel)

    mark_poem_as_tweeted!(conn, poem)
  end

  def prepare_poem_text(poem: poem, author: author, hashtags: hashtags) do
    # Trim leading and trailing whitespaces:
    poem_arr =
      poem.body
      |> String.split("\n")
      |> Enum.map(fn s -> String.trim(s) end)

    poem_arr = if poem.title, do: ["«#{poem.title}»" | poem_arr], else: poem_arr
    poem_arr = poem_arr ++ ["\n"]
    poem_arr = if author.name, do: poem_arr ++ ["#{author.name}"], else: poem_arr
    poem_arr = if poem[:year], do: poem_arr ++ ["#{poem[:year]}"], else: poem_arr
    if hashtags, do: poem_arr ++ ["\n#{hashtags}"], else: poem_arr
  end

  def split_text_into_threads(arr) do
    chunk_fun = fn element, acc ->
      if String.length(Enum.join([element | acc], "\n")) > 280 do
        {:cont, Enum.reverse(acc), [element]}
      else
        {:cont, [element | acc]}
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    Enum.chunk_while(arr, [], chunk_fun, after_fun)
  end

  def tweet_a_thread(arr) do
    Enum.reduce(arr, 0, fn lines, tweet_id ->
      tweet_body = Enum.join(lines, "\n")

      tweet =
        if tweet_id == 0 do
          ExTwitter.update(tweet_body)
        else
          ExTwitter.update(tweet_body, in_reply_to_status_id: tweet_id)
        end

      tweet.id
    end)

    arr
  end

  def post_to_telegram(arr, telegram_channel) do
    post_body = Enum.join(arr, "\n")
    token = System.get_env("POEM_TELEGRAM_TOKEN")

    Telegram.Api.request(token, "sendMessage",
      chat_id: telegram_channel,
      text: post_body
    )

  end
end
