FROM elixir:1.16.1-alpine

ARG NODE_NAME
ENV NODE_NAME $NODE_NAME

WORKDIR /app

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

RUN mix compile

# CMD elixir --sname $NODE_NAME --erl "+P 500000" --cookie supersecretcookie -S mix run --no-halt
CMD elixir --sname $NODE_NAME --cookie supersecretcookie -S mix run --no-halt