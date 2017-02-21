defmodule Ueberauth.Strategy.Goodreads do
  @moduledoc """
  Goodreads Strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :id_str

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Goodreads
  import SweetXml

  @doc """
  Handles initial request for Goodreads authentication.
  """
  def handle_request!(conn) do
    token = Goodreads.OAuth.request_token!([], [redirect_uri: callback_url(conn)])
    conn
    |> put_session(:goodreads_token, token)
    |> redirect!(Goodreads.OAuth.authorize_url!(token))
  end

  @doc """
  Handles the callback from Goodreads.
  """
  def handle_callback!(%Plug.Conn{params: %{"authorize" => oauth_verifier}} = conn) do
    token = get_session(conn, :goodreads_token)
    case Goodreads.OAuth.access_token(token, oauth_verifier) do
      {:ok, access_token} -> fetch_user(conn, access_token)
      {:error, error} -> set_errors!(conn, [error(error.code, error.reason)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:goodreads_user, nil)
    |> put_session(:goodreads_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.goodreads_user[uid_field]
  end

  @doc """
  Includes the credentials from the Goodreads response.
  """
  def credentials(conn) do
    {token, secret} = conn.private.goodreads_token

    %Credentials{token: token, secret: secret}
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.goodreads_user

    %Info{
      name: user["name"],
      urls: %{
        Goodreads: user["link"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Goodreads callback.
  """
  def extra(conn) do
    {token, _secret} = get_session(conn, :goodreads_token)

    %Extra{
      raw_info: %{
        token: token,
        user: conn.private.goodreads_user
      }
    }
  end

  defp fetch_user(conn, token) do
    params = [include_entities: false, skip_status: true, include_email: true]
    case Goodreads.OAuth.get("/api/auth_user", params, token) do
      {:ok, {{_, 401, _}, _, _}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, {{_, status_code, _}, _, body}} when status_code in 200..399 ->
        body = %{
          "id" => body |> xpath(~x"//user/@id"),
          "name" => body |> xpath(~x"//user/name/text()"),
          "link" => body |> xpath(~x"//user/link/text()")
        }
        conn
        |> put_private(:goodreads_token, token)
        |> put_private(:goodreads_user, body)
      {:ok, {_, _, body}} ->
        set_errors!(conn, [error("user", "fetch user error")])
    end
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end
end