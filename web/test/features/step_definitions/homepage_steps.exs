defmodule Memba.Cucumber.HomepageSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions
  import Phoenix.ConnTest

  @endpoint MembaWeb.Endpoint

  step "I visit the homepage", context do
    Map.put(context, :conn, build_conn() |> get("/"))
  end

  step "I should see the Memba homepage", context do
    conn = Map.fetch!(context, :conn)
    html = html_response(conn, 200)

    assert html =~ "Memba · Phoenix Framework"

    context
  end
end
