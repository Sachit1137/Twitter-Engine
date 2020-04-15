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
    :ets.new(:pid_users, [:named_table, :public])
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

  def handle_call({:register, user_name, _socket}, list_clients, state) do


    (:ets.insert(:users, {list_clients |> elem(0), 1, 0}))
    (:ets.insert(:pid_users, {user_name, list_clients |> elem(0)}))
    (:ets.insert(:followers, {user_name, []}))
    (:ets.insert(:tweets_received, {user_name, []}))
    (:ets.insert(:tweets_send, {user_name, []}))

    {:reply, :registered, state}
  end

  def handle_call({:subscribe_web, usersToSub, user_name}, _list_clients, state) do
    client_pid2 = getPID(user_name)

    :ets.insert(:tweets_received, {client_pid2, []})

    [{_, list_followers}] = :ets.lookup(:followers, usersToSub)
    (:ets.insert(:followers, {usersToSub, list_followers ++ [client_pid2]}))


    {:reply, {:subscribed}, state}
  end

  def handle_call({:hashtag_query, tweet_name}, _list_clients, state) do

    if :ets.member(:hashtag, tweet_name) == false do
      {:reply, ["#Dummmyhashtag"], state}
    else
      [{_, list_msg}] = :ets.lookup(:hashtag, tweet_name)
      {:reply, list_msg, state}
    end
  end

  def handle_call({:mentions_query, mention_name}, _list_clients, state) do

    if :ets.member(:mention, mention_name) == false do
      {:reply, ["#DummmyMention"], state}
    else
      [{_, list_msg}] = :ets.lookup(:mention, mention_name)
      {:reply, list_msg, state}
    end
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

  def handle_call({:tweet_HT, tweetText, userName, _subscriber, index_space}, _from, state) do
    [{_, list_of_followers}] = :ets.lookup(:followers, userName)

    Enum.each(list_of_followers, fn follower ->
      [{_, notification1}] = :ets.lookup(:tweets_send, userName)

      :ets.insert(:tweets_send, {userName, notification1 ++ [tweetText]})

      [{_, notification2}] = :ets.lookup(:tweets_received, follower)

      :ets.insert(:tweets_received, {follower, notification2 ++ [tweetText]})
      space = String.at(tweetText, index_space)
      words = String.split(tweetText, space)
      :ets.insert(:hashtag, {Enum.at(words, 0), [tweetText]})
    end)

    {:reply, state, state}
  end

  def handle_call({:tweet_MN, tweetText, userName, _subscriber, index_space}, _from, state) do
    [{_, list_of_followers}] = :ets.lookup(:followers, userName)

    Enum.each(list_of_followers, fn follower ->
      [{_, notification1}] = :ets.lookup(:tweets_send, userName)

      :ets.insert(:tweets_send, {userName, notification1 ++ [tweetText]})

      [{_, notification2}] = :ets.lookup(:tweets_received, follower)

      :ets.insert(:tweets_received, {follower, notification2 ++ [tweetText]})
      space = String.at(tweetText, index_space)
      words = String.split(tweetText, space)
      :ets.insert(:mention, {Enum.at(words, 0), [tweetText]})
    end)

    {:reply, state, state}
  end

  def handle_call({:tweet_HT_MN, tweetText, userName, _subscriber, index_space}, _from, state) do
    [{_, list_of_followers}] = :ets.lookup(:followers, userName)

    Enum.each(list_of_followers, fn follower ->
      [{_, notification1}] = :ets.lookup(:tweets_send, userName)

      :ets.insert(:tweets_send, {userName, notification1 ++ [tweetText]})

      [{_, notification2}] = :ets.lookup(:tweets_received, follower)

      :ets.insert(:tweets_received, {follower, notification2 ++ [tweetText]})
      space = String.at(tweetText, index_space)
      words = String.split(tweetText, space)
      # hashtag --> 0
      # mention --> 1
      :ets.insert(:hashtag, {Enum.at(words, 0), words -- [Enum.at(words, 1)]})
      :ets.insert(:mention, {Enum.at(words, 1), [tweetText]})
    end)

    {:reply, state, state}
  end

  def handle_cast({:tweet_subscribers, tweetText, userName}, state) do
    [{_, list_of_followers}] = :ets.lookup(:followers, userName)

    Enum.each(list_of_followers, fn follower ->
      [{_, notification1}] = :ets.lookup(:tweets_send, userName)

      :ets.insert(:tweets_send, {userName, notification1 ++ [tweetText]})

      [{_, notification2}] = :ets.lookup(:tweets_received, follower)

      :ets.insert(:tweets_received, {follower, notification2 ++ [tweetText]})
    end)

    {:noreply, state}
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

  def getPID(username) do
    [{_, pid}] = :ets.lookup(:pid_users, username)
    pid
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
