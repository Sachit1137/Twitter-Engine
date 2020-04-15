defmodule Project4.Execution do
  def main(server) do
    input = [100,10]
    server_node = String.to_atom("server@127.0.0.1")

    if(server == "server") do
      # IO.puts "inside servre"
      start_server(server_node)
    else
      [num_users, num_tweets] = input
      num_users = String.to_integer(num_users)
      num_tweets = String.to_integer(num_tweets)
      client_node = String.to_atom("Client@127.0.0.1")
      Node.start(client_node)
      Node.set_cookie(:twitter)
      Node.connect(server_node)
      :global.sync()

      GenServer.call({:server, server_node}, {:engine_started, client_node}, 500_000)

      pid = Project4.ClientSupervisor.start(num_users)
      GenServer.call({:server, server_node}, {:initialize_state, pid, num_users, num_tweets})

      Project4.Client.create_account(pid, num_users)

      GenServer.cast({:server, server_node}, :registration_finished)

      start_time = System.monotonic_time(:millisecond)
      Project4.Driver.send_tweets(pid, self(), num_users, num_tweets, start_time)
    end
  end

  def start_server(server_node) do
    Node.start(server_node)
    Node.set_cookie(:twitter)
    IO.puts("Starting twitter engine on node #{server_node}")
    Project4.ServerSupervisor.start()
    :global.sync()
    :global.register_name(:runner, self())
    Project4.Execution.keep_running()
  end

  def keep_running() do
    receive do
      {:completed, start_time} ->
        server_node = String.to_atom("server@127.0.0.1")
        end_time = System.monotonic_time(:millisecond)
        total_time = end_time - start_time
        counter = GenServer.call({:server, server_node}, :fetch_counter)

        IO.inspect(counter, label: "total activities performed by the server")
        IO.inspect(total_time/1000, label: "total time taken(seconds)")
        IO.inspect(counter / (total_time/1000), label: "activities performed per second")
    end

    keep_running()
  end
end


defmodule Project4.Driver do
  def keep_running_for_client(pid,pid_call,total_users,total_tweets,start_time) do
      server_name = String.to_atom("server@127.0.0.1")

      count_list_value = Enum.filter(GenServer.call({:server,server_name},:count,500_000), fn count->
          count >= total_tweets
      end)

      if(length(count_list_value) == total_users) do
          :global.sync()
          send(:global.whereis_name(:runner),{:completed,start_time})
      else
          keep_running_for_client(pid,pid_call,total_users,total_tweets,start_time)
      end
  end

  def send_tweets(pid,pid_call,total_users,total_tweets,start_time) do
      Enum.each(pid, fn pid_id->
          GenServer.cast(pid_id, :rand_operation)
      end)
      keep_running_for_client(pid,pid_call,total_users,total_tweets,start_time)
  end
end
