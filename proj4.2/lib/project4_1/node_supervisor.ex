defmodule Project4.NodeSupervisor do
  def start(total_users) do
    list = Enum.to_list(1..total_users)

    children =
      Enum.map(list, fn x ->
        Supervisor.child_spec({Proj4.Node, []}, id: x, restart: :permanent)
      end)

    opts = [strategy: :one_for_one, name: Proj4.NodeSupervisor]
    Supervisor.start_link(children, opts)

    Enum.map(Supervisor.which_children(Proj4.NodeSupervisor), fn {_, child, _, _} -> child end)
  end
end
