# Phreak

A simple Kubernetes dashboard with Elixir, Phoenix, LiveView. No external 
dependencies.

Ad-hoc code, no documentation for now. In action: https://www.youtube.com/watch?v=vOaZ_AspfKc 


# How

```bash

> cd phreak
> mix deps.get
> cd assets && npm install
> cd -
> iex -S mix phx.server 

```

Open http://localhost:4000/kube

# Requirements

You must have `~/.kube/config` yaml configuration (if you run stuff on GCP, you
will have it).



