defmodule Discuss.TopicController do

### use designates to phoenix what this file is for. we pass in its purpose as an atom. in this case, :controller ###
  use Discuss.Web, :controller

### alias allows us to quickly grab functions from other modules. this for instance grabs functions from Topic.ex in /web/models/topic.ex ###

  alias Discuss.Topic

  plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_owner when action in [:update, :edit, :delete]

### each function in a controller will handle serving requests routed from /web/router.ex. ###
### we take in a `conn`ection, and we assume there will be parameters, but we do not care what the parameters actually are. ###
### we match topics, to all the database values using Repo.all, passing in the db schema from Topic.ex (remember alias?) ###
### then, we `render` a connection, utilizing the index.html.eex template in /web/templates/topics/, ###
### passing in the topics function from that template with the parameters from our topics object. ###

  def index(conn, _params) do
    topics = Repo.all(Topic)
    render conn, "index.html", topics: topics
  end

  def show(conn, %{"id" => topic_id}) do
    topic = Repo.get!(Topic, topic_id)
    render conn, "show.html", topic: topic
  end

### Here we have the function for making a new field in our database. it takes two arguments "conn" (connection passed by phoenix) ###
### We define a changeset, being a data set, we wish to change in our database. We use this term to call back to the changeset function - ###
### in our model, /web/models/topic.ex. we pass in the schema, as "%Topic{}, %{}. ###
### Then, we tell phoenix to render a page for the connection, pulling from the new.html.eex template in the template directory ###

   def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})

    render conn, "new.html", changeset: changeset
  end

### Here is our create function, which is called by the router with a post request to /topics. ###
### this is used whenever someones triggers the create function by clicking the save topic button we made in /web/templates/topics/new.html.eex ###
### we take a connection, and pass a map that contains a string as the key. (note the => operator is in use for this kind of map.) ###
### without this syntax, the function breaks, not only because elixir/phoenix demand it, ###
### but because we need a string for postgresql to even parse the request. ###
### we make a local changeset using our db schema, passing in the topic variable we pattern matched from the connection. ###
### then we have a case condition, for inserting our changeset data ###
### if the insert works, Repo will return a tuple- ":ok, input var""  do not stat the topic params, then pass them in to the db ###
### we also return a connection, piping in a flash message, onto our index webpage. ###
### if the insert fails, Repo will return another tuple, ":error, output_changeset"
### here the changeset will contain our error statement, so we passit to the form. ###

  def create(conn, %{"topic" => topic}) do
    #changeset = Topic.changeset(%Topic{}, topic)
    changeset = conn.assigns.user
      |> build_assoc(:topics)
      |> Topic.changeset(topic)

    case  Repo.insert(changeset) do
      {:ok, _topic} ->
        conn
          |> put_flash(:info, "Topic Created")
          |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

### below is our edit handler function, surely you understand the pattern now - we take in a connection and inspect it's parameters, being ###
### the string passed in by the :id atom (this is a wildcard, it takes browser input) in our router. ###
### we map the ID by matching it with our Repo.get function, to the corresponding database entry. effectively, this becomes - ###
### - { :id => topic_id } = { table_value => table_data }, then we say that whole object should be passed by topic. ###
### we make a changeset with the value of a _currently_ existing table entry ###
### then we render the connection, making sure to pass both the topic, and the changeset, ###
### so that our edit  page shows the value, and knows we're editing the changeset data ###

  def edit(conn, %{"id" => topic_id}) do
    topic = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(topic)
    render conn, "edit.html",  topic: topic, changeset: changeset
  end

### Below we actually update a database value, taken in by the edit form we just made. we pass the string "id" from the connection ###
### and attach it to a local pattern `topic_id`,(that is the table entry) and we do the same with ###
### the value in the database and the topic variable. now we match old_topic, to the current database value ###
### we then match the changeset variable to a map, %{ old_topic => topic } ###
### then, we pass it to our case statement for success or failure ###

  def update(conn, %{"id" => topic_id, "topic" => topic}) do
    old_topic = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(old_topic, topic)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic Updated")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        render conn, "edit.html", changeset: changeset, topic: old_topic
    end
  end

  def delete(conn, %{"id" => topic_id}) do
    Repo.get!(Topic, topic_id) |> Repo.delete!

    conn
    |> put_flash(:info, "Topic Deleted")
    |> redirect(to: topic_path(conn, :index))
  end

### plugs do not automatically receive their parameters from connections - ###
### in order to pass those in, we pattern match on the second line below ###
  def check_topic_owner(conn, _params) do
    %{params: %{"id" => topic_id}} = conn
### if the topic_id from database:table:id:user_id is the same as the connections user_id, return the connection - ###
### otherwise, fail, redirect to the index function, and halt, ensuring no further plugs receive this connection ###
    if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
      conn
    else
      conn
      |> put_flash(:error, "Failed, Do you own this Topic?")
      |> redirect(to: topic_path(conn, :index))
      |> halt()
    end
  end

end
