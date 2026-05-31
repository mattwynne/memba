# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=27
ARG DEBIAN_VERSION=bookworm
ARG BUILDER_IMAGE="elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}-slim"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY web/mix.exs web/mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY web/config/config.exs web/config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY web/priv priv
COPY web/lib lib
COPY web/assets assets

RUN mix compile
RUN mix assets.deploy

COPY web/config/runtime.exs config/
COPY web/rel rel
RUN mix release

FROM ${RUNNER_IMAGE} AS runner

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    MIX_ENV=prod

WORKDIR /app
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/memba ./

USER nobody

CMD ["/app/bin/server"]
