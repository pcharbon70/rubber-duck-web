defmodule RubberduckWebWeb.PageControllerTest do
  use RubberduckWebWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    assert response =~ "RubberDuck"
    assert response =~ "collaborative"
  end
end
