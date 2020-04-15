defmodule Project4.ServerSupervisor do
  def start() do
    children = [
      Supervisor.child_spec({Project4.Server, []}, id: Project4.Server, restart: :permanent)
    ]

    options = [strategy: :one_for_one, name: Project4.ServerSupervisor]
    Supervisor.start_link(children, options)
  end
end

defmodule Project4.Server do
  use GenServer

  def start_link(args) do
    {:ok, pid} = GenServer.start_link(__MODULE__, args, name: :server)
    {:ok, pid}
  end

  @spec init(any) :: {:ok, {}}
  def init(_state) do
    :ets.new(:users, [:named_table, :public])
    :ets.new(:followers, [:named_table, :public])
    :ets.new(:followers_in, [:named_table, :public])
    :ets.new(:tweets_send, [:named_table, :public])
    :ets.new(:tweets_received, [:named_table, :public])
    :ets.new(:hashtag, [:named_table, :public])
    :ets.new(:mention, [:named_table, :public])
    {:ok, {}}
  end

  def handle_call(:count, _from, state) do
    {pid, total_users, total_msgs, counter} = state

    msg_list =
      Enum.map(pid, fn pid_id ->
        [{_, _, msg_counter}] = :ets.lookup(:users, pid_id)
        msg_counter
      end)

    {:reply, msg_list, {pid, total_users, total_msgs, counter}}
  end

  def handle_call({:engine_started, address}, _, state) do
    client_node = address
    IO.puts("#{client_node} Connected.")
    {:reply, state, state}
  end

  def handle_call({:fetch_tweets, user_pid}, _from, state) do
    [{_, tweets}] = :ets.lookup(:tweets_send, user_pid)
    {:reply, tweets, state}
  end

  def handle_call({:fetch_feed, user_pid}, _from, {pid, total_users, total_msgs, counter}) do
    [{_, notification}] = :ets.lookup(:tweets_received, user_pid)
    {:reply, notification, {pid, total_users, total_msgs, counter + 1}}
  end

  def handle_call({:fetch_hashtags, hashtag}, _from, {pid, total_users, total_msgs, counter}) do
    [{_, notification}] = :ets.lookup(:hashtag, hashtag)
    {:reply, notification, {pid, total_users, total_msgs, counter + 1}}
  end

  def handle_call({:fetch_followers, client_pid}, _from, state) do
    [{_, following}] = :ets.lookup(:followers, client_pid)
    {:reply, following, state}
  end

  def handle_call({:fetch_mentions, mention}, _from, {pid, total_users, total_msgs, counter}) do
    [{_, notification}] = :ets.lookup(:mention, mention)
    {:reply, notification, {pid, total_users, total_msgs, counter + 1}}
  end

  def handle_call({:fetch_users}, _from, {pid, total_users, total_msgs, counter}) do
    {:reply, pid, {pid, total_users, total_msgs, counter + 1}}
  end

  def handle_call({:fetch_mentions, mention}, _from, state) do
    [{_, msg_list}] = :ets.lookup(:mention, mention)
    {:reply, msg_list, state}
  end

  def handle_call(:fetch_counter, _from, {pid, total_users, total_msgs, counter}) do
    {:reply, counter, {pid, total_users, total_msgs, counter}}
  end

  def handle_call({:initialize_state, pid, total_users, total_msgs}, _from, state) do
    {:reply, state, {pid, total_users, total_msgs, 0}}
  end

  def handle_call({:fill_hashtag, msg_list}, _from, state) do
    Enum.each(msg_list, fn pid_id ->
      :ets.insert(:hashtag, {pid_id, []})
    end)

    {:reply, state, state}
  end

  def handle_call({:fill_mention, pid}, _from, state) do
    Enum.each(pid, fn pid_id ->
      :ets.insert(:mention, {pid_id, []})
    end)

    {:reply, state, state}
  end

  def handle_call({:create_account, user_pid}, _from, {pid, total_users, total_msgs, counter}) do
    :ets.insert(:users, {user_pid, 1, 0})
    :ets.insert(:tweets_send, {user_pid, []})
    :ets.insert(:tweets_received, {user_pid, []})
    :ets.insert(:followers_in, {user_pid, []})
    {:reply, {pid, total_users, total_msgs}, {pid, total_users, total_msgs, counter + 1}}
  end

  def handle_call(
        {:follow, user_pid, followers},
        _from,
        {pid, total_users, total_msgs, counter}
      ) do
    :ets.insert(:followers, {user_pid, followers})

    Enum.map(followers, fn pid_id ->
      [{_, followers}] = :ets.lookup(:followers_in, pid_id)
      followers = followers ++ [user_pid]
      :ets.insert(:followers_in, {pid_id, followers})
    end)

    {:reply, {pid, total_users, total_msgs}, {pid, total_users, total_msgs, counter + 1}}
  end

  def handle_cast(
        {:send_tweet_mention, user_pid, tweet, mention_pid},
        {pid, total_users, total_msgs, counter}
      ) do
    [{_, _, msg_counter}] = :ets.lookup(:users, user_pid)

    if(msg_counter <= total_msgs) do
      [{_, msg_list}] = :ets.lookup(:tweets_send, user_pid)
      msg_list = msg_list ++ [tweet]
      :ets.insert(:tweets_send, {user_pid, msg_list})
      [{_, followers}] = :ets.lookup(:followers_in, user_pid)

      Enum.each(followers, fn pid_id ->
        [{_, notification}] = :ets.lookup(:tweets_received, pid_id)
        notification = notification ++ [tweet]
        :ets.insert(:tweets_received, {pid_id, notification})
      end)

      [{_, msg_list}] = :ets.lookup(:mention, mention_pid)
      msg_list = msg_list ++ [tweet]
      :ets.insert(:mention, {mention_pid, msg_list})
    end

    msg_counter = msg_counter + 1
    :ets.insert(:users, {user_pid, 1, msg_counter})
    {:noreply, {pid, total_users, total_msgs, counter + 1}}
  end

  def handle_cast(:registration_finished, state) do
    IO.puts("User registeration finished")
    IO.puts("Start tweeting")
    {:noreply, state}
  end

  def handle_cast({:send_tweet, user_pid, tweet}, {pid, total_users, total_msgs, counter}) do
    [{_, _, msg_counter}] = :ets.lookup(:users, user_pid)

    if(msg_counter <= total_msgs) do
      [{_, msg_list}] = :ets.lookup(:tweets_send, user_pid)
      msg_list = msg_list ++ [tweet]
      :ets.insert(:tweets_send, {user_pid, msg_list})
      [{_, followers}] = :ets.lookup(:followers_in, user_pid)

      Enum.each(followers, fn pid_id ->
        [{_, notification}] = :ets.lookup(:tweets_received, pid_id)
        notification = notification ++ [tweet]
        :ets.insert(:tweets_received, {pid_id, notification})
      end)

      insert_hashtags(tweet)
    end

    msg_counter = msg_counter + 1
    :ets.insert(:users, {user_pid, 1, msg_counter})
    {:noreply, {pid, total_users, total_msgs, counter + 1}}
  end

  def login(pid) do
    [{_, connected, _}] = :ets.lookup(:users, pid)

    if(connected == 1) do
      true
    else
      false
    end
  end

  def create_user_acc(pid) do
    [{user_pid, _, _}] = :ets.lookup(:users, pid)

    if(user_pid == pid) do
      true
    else
      false
    end
  end

  def insert_hashtags(tweet) do
    if(length(String.split(tweet, "#")) != 1) do
      [_, hashtag] = String.split(tweet, "#")
      hashtag = "#" <> hashtag
      [{_, msg_list}] = :ets.lookup(:hashtag, hashtag)
      msg_list = msg_list ++ [tweet]
      :ets.insert(:hashtag, {hashtag, msg_list})
    end
  end

  def logout(pid) do
    :ets.insert(:users, {pid, 0, 0})

    [{_, connected, _}] = :ets.lookup(:users, pid)

    if(connected == 0) do
      true
    else
      false
    end
  end
end
