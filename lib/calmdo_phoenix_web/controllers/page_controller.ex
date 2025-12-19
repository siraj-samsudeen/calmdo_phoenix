defmodule CalmdoPhoenixWeb.PageController do
  use CalmdoPhoenixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
