defmodule Project4.ClientSupervisor do
  def start(total_users) do
    children =
      Enum.map(Enum.to_list(1..total_users), fn user ->
        Supervisor.child_spec({Project4.Client, []}, id: user, restart: :permanent)
      end)

    supervisor_status =
      Supervisor.start_link(children, strategy: :one_for_one, name: Project4.ClientSupervisor)

    case supervisor_status do
      {:ok, _} ->
        :ok

      {:error, _} ->
        IO.puts("Supervisor did not start.Please run mix test again")
        System.halt(0)
    end

    Enum.map(Supervisor.which_children(Project4.ClientSupervisor), fn {_, pid, _, _} -> pid end)
  end
end

defmodule Project4.Client do
  use GenServer

  def start_link(node) do
    {:ok, pid} = GenServer.start_link(__MODULE__, node)
    {:ok, pid}
  end

  def init(_args) do
    {:ok, 0}
  end

  @spec create_account(any, any) :: any
  def create_account(pid, total_users) do
    server_address = String.to_atom("server@127.0.0.1")

    Enum.map(pid, fn pid_id ->
      GenServer.call({:server, server_address}, {:create_account, pid_id}, 500_000)
    end)

    Enum.map(pid, fn pid_id ->
      GenServer.call(
        {:server, server_address},
        {:follow, pid_id,
         Enum.take_random(pid -- [pid_id], Enum.random(Enum.to_list(2..total_users)))},
        500_000
      )
    end)

    GenServer.call(
      {:server, server_address},
      {:fill_hashtag,
       ["#Hashtag1", "#Hashtag2", "#Hashtag3", "#Hashtag4", "#Hashtag5", "#Hashtag6"]},
      500_000
    )

    GenServer.call({:server, server_address}, {:fill_mention, pid}, 500_000)
  end

  def handle_cast(:rand_operation, state) do
    rand_num = Enum.random(Enum.to_list(1..7))

    if rand_num == 1 do
      send_tweet()
    else
      if rand_num == 2 do
        retweet()
      else
        if rand_num == 3 do
          mention()
        else
          if rand_num == 4 do
            read_notification()
          else
            if rand_num == 5 do
              send_tweet_hashtag()
            else
              if rand_num == 6 do
                query_hashtag()
              else
                send_tweet_mentions()
              end
            end
          end
        end
      end
    end

    GenServer.cast(self(), :rand_operation)
    {:noreply, state}
  end

  def fetch_hashtag() do
    Enum.random(["#Hashtag1", "#Hashtag2", "#Hashtag3", "#Hashtag4", "#Hashtag5", "#Hashtag6"])
  end

  def send_tweet() do
    server_address = String.to_atom("server@127.0.0.1")
    GenServer.cast({:server, server_address}, {:send_tweet, self(), fetch_tweet()})
  end

  def retweet() do
    server_address = String.to_atom("server@127.0.0.1")

    users_wall = GenServer.call({:server, server_address}, {:fetch_feed, self()}, 500_000)

    if(length(users_wall) > 0) do
      tweet = "RT " <> Enum.random(users_wall)

      if(length(String.split(tweet, "@")) == 1) do
        GenServer.cast({:server, server_address}, {:send_tweet, self(), tweet})
      end
    end
  end

  def mention() do
    server_address = String.to_atom("server@127.0.0.1")

    pid_users = GenServer.call({:server, server_address}, {:fetch_users}, 500_000)

    GenServer.call(
      {:server, server_address},
      {:fetch_mentions, Enum.random(pid_users -- [self()])},
      500_000
    )
  end

  def read_notification() do
    server_address = String.to_atom("server@127.0.0.1")

    notifications = GenServer.call({:server, server_address}, {:fetch_feed, self()}, 500_000)

    if(length(notifications) > 0) do
      IO.inspect(notifications, label: "user's wall")
    end
  end

  def send_tweet_hashtag() do
    server_address = String.to_atom("server@127.0.0.1")

    GenServer.cast(
      {:server, server_address},
      {:send_tweet, self(), fetch_tweet() <> fetch_hashtag()}
    )
  end

  def query_hashtag() do
    server_address = String.to_atom("server@127.0.0.1")
    GenServer.call({:server, server_address}, {:fetch_hashtags, fetch_hashtag()}, 500_000)
  end

  def send_tweet_mentions() do
    server_address = String.to_atom("server@127.0.0.1")
    pid_users = GenServer.call({:server, server_address}, {:fetch_users}, 500_000)

    GenServer.cast(
      {:server, server_address},
      {:send_tweet_mention, self(),
       fetch_tweet() <> "@" <> inspect(Enum.random(pid_users -- [self()])),
       Enum.random(pid_users -- [self()])}
    )
  end

  def fetch_tweet() do
    Enum.random([
      "Tweet1",
      "Tweet2",
      "Tweet3",
      "Tweet4",
      "Tweet5",
      "Tweet6",
      "Tweet7",
      "Tweet8",
      "Tweet9",
      "Tweet10",
      "Tweet11",
      "Tweet12"
    ])
  end
end
