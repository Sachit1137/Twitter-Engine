defmodule TwitterWeb.TwitterChannel do
  use TwitterWeb, :channel

  def join("twitter:lobby", payload, socket) do
    {:ok, socket}
  end

  def handle_in("shout", payload, socket) do

    broadcast(socket, "shout", payload)

    {:noreply, socket}
  end

  def handle_in("shout_again", payload, socket) do
    #IO.inspect(payload, label: "broadcast payload")

    broadcast(socket, "shout_again", payload)

    {:noreply, socket}
  end

  def handle_in("register", userName, socket) do
    server_address = String.to_atom("server@127.0.0.1")
    # IO.inspect(socket, label: "socket")
    GenServer.call({:server, server_address}, {:register, userName, socket})
    push(socket, "registered", %{"userName" => userName})
    {:reply, :registered, socket}
  end

  def handle_in("subscribe", payload, socket) do
    server_address = String.to_atom("server@127.0.0.1")
    # IO.inspect(payload, label: "payload")
    user_name = payload["username"]
    usersToSub = payload["usersToSub"]
    # IO.inspect(usersToSub, label: "userToSubs")
    GenServer.call({:server, server_address}, {:subscribe_web, usersToSub, user_name})
    push(socket, "subscribed", %{"userName" => user_name})
    {:reply, :subscribed, socket}
  end

  def handle_in("tweetsearch", payload, socket) do
    server_address = String.to_atom("server@127.0.0.1")
    # IO.inspect(payload, label: "payload")
    tweet_name = payload["tweetValue"]
    # IO.inspect(tweet_name, label: "tweet_name")
    tweetmsg_list = GenServer.call({:server, server_address}, {:hashtag_query, tweet_name})
    # IO.inspect(tweetmsg_list, label: "tweetmsg_list")
    push(socket, "tweetreceive", %{"tweet_Value" => tweetmsg_list})
    {:reply, :tweetreceive, socket}
  end

  def handle_in("mentionsearch", payload, socket) do
    server_address = String.to_atom("server@127.0.0.1")
    # IO.inspect(payload, label: "payload")
    mention_name = payload["mentionValue"]
    # IO.inspect(mention_name, label: "mention_name")
    mention_list = GenServer.call({:server, server_address}, {:mentions_query, mention_name})
    # IO.inspect(mention_list, label: "mention_list")
    push(socket, "mentionreceive", %{"mention_Value" => mention_list})
    {:reply, :mentionreceive, socket}
  end

  def handle_in("retweet", payload, socket) do
    userName = payload["username"]
    tweetText = payload["tweetText"]
    server_address = String.to_atom("server@127.0.0.1")

    GenServer.cast(
      {:server, server_address},
      {:tweet_subscribers, "RT" <> tweetText, userName}
    )

    {:noreply, socket}
  end

  def handle_in("sendtweet", payload, socket) do
    tweetText = payload["tweetText"]
    userName = payload["username"]
    subscriber = payload["subs"]
    server_address = String.to_atom("server@127.0.0.1")

    GenServer.cast(
      {:server, server_address},
      {:tweet_subscribers, tweetText, userName}
    )

    push(socket, "tweeted", %{"userName" => userName})

    push(socket, "reTweet", %{"userName" => userName, "tweetText" => tweetText, "subscriber" => subscriber})

    {:noreply, socket}
  end

  def handle_in("sendtweetHT", payload, socket) do
    tweetText = payload["tweetText"]
    userName = payload["username"]
    subscriber = payload["subs"]
    index = payload["index"]
    server_address = String.to_atom("server@127.0.0.1")

    GenServer.call(
      {:server, server_address},
      {:tweet_HT, tweetText, userName, subscriber, index}
    )

    push(socket, "tweeted", %{"userName" => userName})
    push(socket, "reTweet", %{"userName" => userName, "tweetText" => tweetText, "subscriber" => subscriber})

    {:noreply, socket}
  end

  def handle_in("sendtweetMN", payload, socket) do
    tweetText = payload["tweetText"]
    userName = payload["username"]
    subscriber = payload["subs"]
    index = payload["index"]
    server_address = String.to_atom("server@127.0.0.1")

    GenServer.call(
      {:server, server_address},
      {:tweet_MN, tweetText, userName, subscriber, index}
    )

    push(socket, "tweeted", %{"userName" => userName})
    push(socket, "reTweet", %{"userName" => userName, "tweetText" => tweetText, "subscriber" => subscriber})

    {:noreply, socket}
  end

  def handle_in("sendtweetHT_MN", payload, socket) do
    tweetText = payload["tweetText"]
    userName = payload["username"]
    subscriber = payload["subs"]
    index = payload["index"]
    server_address = String.to_atom("server@127.0.0.1")

    GenServer.call(
      {:server, server_address},
      {:tweet_HT_MN, tweetText, userName, subscriber, index}
    )

    push(socket, "tweeted", %{"userName" => userName})
    push(socket, "reTweet", %{"userName" => userName, "tweetText" => tweetText, "subscriber" => subscriber})

    {:noreply, socket}
  end

end
