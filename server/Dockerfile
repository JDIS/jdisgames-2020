# https://hexdocs.pm/phoenix/releases.html#ecto-migrations-and-custom-commands

FROM elixir:1.13.4-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs yarn python3 npm

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

# build assets
COPY assets assets
COPY priv priv
RUN cd assets && npm install && npm run deploy
RUN mix phx.digest

# build project
COPY lib lib
RUN mix compile

# build release (uncomment COPY if rel/ exists)
# COPY rel rel
RUN mix release

# Generate app secret
RUN mix phx.gen.secret > secret_key.txt

# prepare release image
FROM alpine:3.16.0 AS app
RUN apk add --update bash openssl libstdc++
RUN apk add lsof

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/diep_io ./
COPY --from=build /app/secret_key.txt ./
COPY entrypoint.sh ./
RUN chown -R nobody: /app
RUN chmod +x ./entrypoint.sh
USER nobody

ENV HOME=/app

EXPOSE 80
EXPOSE 443

CMD ["./entrypoint.sh"]
