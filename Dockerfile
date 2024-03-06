FROM elixir:1.16.1-alpine

ARG NODE_NAME
ENV NODE_NAME $NODE_NAME

WORKDIR /app

RUN apk update \
    && apk --no-cache --update add build-base 

COPY lib ./lib
COPY mix.exs ./mix.exs

RUN rm -rf _build

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

ENV MIX_ENV PROD
RUN mix release

