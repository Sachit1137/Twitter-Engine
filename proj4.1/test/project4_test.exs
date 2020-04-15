defmodule Project4Test do
  use ExUnit.Case

  setup do
    server_address = String.to_atom("server@127.0.0.1")
    Node.start(server_address)
    Node.set_cookie(:Project4)
    Project4.ServerSupervisor.start()
    pid_list = Project4.ClientSupervisor.start(10)
    GenServer.call({:server, server_address}, {:initialize_state, pid_list, 10, 1})
    Project4.Client.create_account(pid_list, 10)
    :ok
  end

  test "check_create_user_account" do
    server_address = String.to_atom("server@127.0.0.1")
    GenServer.call({:server, server_address}, {:create_account, self()})
    assert Project4.Server.create_user_acc(self()) == true
  end

  test "check_user_status" do
    server_address = String.to_atom("server@127.0.0.1")
    GenServer.call({:server, server_address}, {:create_account, self()})
    assert Project4.Server.login(self()) == true
    assert Project4.Server.logout(self()) == true
  end

  test "query_tweet_containing_mention" do
    server_address = String.to_atom("server@127.0.0.1")

    pid = GenServer.call({:server, server_address}, {:fetch_users})
    follower = Enum.random(pid)
    mention = Enum.random(pid)
    tweet = "Tweet1" <> inspect(mention)
    GenServer.cast({:server, server_address}, {:send_tweet_mention, follower, tweet, mention})
    assert GenServer.call({:server, server_address}, {:fetch_mentions, mention}) != nil
  end

  test "check_follower_received_tweets" do
    server_address = String.to_atom("server@127.0.0.1")

    pid = GenServer.call({:server, server_address}, {:fetch_users})
    follower = Enum.random(pid)
    tweet = "Tweet1"
    GenServer.cast({:server, server_address}, {:send_tweet, follower, tweet})
    list_of_followers = GenServer.call({:server, server_address}, {:fetch_followers, follower})
    list_of_followers = Enum.random(list_of_followers)
    assert GenServer.call({:server, server_address}, {:fetch_feed, list_of_followers}) != nil
  end

  test "check_tweet_containing_hashtags" do
    server_address = String.to_atom("server@127.0.0.1")

    pid = GenServer.call({:server, server_address}, {:fetch_users})
    follower = Enum.random(pid)
    tweet = "Tweet1#Hashtag1"
    hashtag = "#Hashtag1"
    GenServer.cast({:server, server_address}, {:send_tweet, follower, tweet})
    assert GenServer.call({:server, server_address}, {:fetch_hashtags, hashtag}) != nil
  end

  test "check_send_tweet" do
    server_address = String.to_atom("server@127.0.0.1")

    pid = GenServer.call({:server, server_address}, {:fetch_users})
    # take 2 random follower
    follower = Enum.take_random(pid, 2)
    GenServer.call({:server, server_address}, {:create_account, self()})
    GenServer.call({:server, server_address}, {:follow, self(), follower})
    tweet = "Tweet1"
    GenServer.cast({:server, server_address}, {:send_tweet, self(), tweet})
    assert GenServer.call({:server, server_address}, {:fetch_tweets, self()}) != nil
  end

  test "check_retweet_functionality" do
    server_address = String.to_atom("server@127.0.0.1")

    pid = GenServer.call({:server, server_address}, {:fetch_users})
    follower = Enum.random(pid)
    tweet = "Tweet1"
    GenServer.cast({:server, server_address}, {:send_tweet, follower, tweet})
    list_of_followers = GenServer.call({:server, server_address}, {:fetch_followers, follower})
    list_of_followers = Enum.random(list_of_followers)
    notification = GenServer.call({:server, server_address}, {:fetch_feed, list_of_followers})

    if notification != [] do
      tweet = "RT" <> Enum.random(notification)
      GenServer.cast({:server, server_address}, {:send_tweet, list_of_followers, tweet})
      assert GenServer.call({:server, server_address}, {:fetch_tweets, list_of_followers}) != nil
    end
  end
end
