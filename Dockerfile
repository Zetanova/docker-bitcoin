FROM ubuntu:20.04 as build
ARG TARGETPLATFORM
ARG BITCOIN_VERSION

ENV SIGNING_KEY=01EA5486DE18A882D4C2684590C8019E36C2E964

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN if [ "${TARGETPLATFORM}" = "linux/amd64" ] || [ "${TARGETPLATFORM}" = "" ]; then export BITCOIN_TARGET=x86_64-linux-gnu; fi \
  && if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then export BITCOIN_TARGET=aarch64-linux-gnu; fi \
  && if [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then export BITCOIN_TARGET=arm-linux-gnueabihf; fi \
  && echo "bitcoin-${BITCOIN_VERSION}-${BITCOIN_TARGET}" \
  && curl -SLO "https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${BITCOIN_TARGET}.tar.gz" \
  && curl -SLO "https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc" \
  && grep " bitcoin-${BITCOIN_VERSION}-${BITCOIN_TARGET}.tar.gz\$" SHA256SUMS.asc | sha256sum -c

RUN gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$SIGNING_KEY" \
  && gpg --verify SHA256SUMS.asc

RUN tar -xzf *.tar.gz -C . \
  && rm *.tar.gz *.asc \
  && rm -rf ./bitcoin-${BITCOIN_VERSION}/bin/bitcoin-qt \
  && mv ./bitcoin-${BITCOIN_VERSION} ./bitcoin


FROM ubuntu:20.04

#ENV BITCOIN_DATA=/home/bitcoin/.bitcoin
ENV PATH=/opt/bitcoin/bin:$PATH

#reduce memory load without perf decrease
#see: https://github.com/bitcoin/bitcoin/blob/master/doc/reduce-memory.md
ENV MALLOC_ARENA_MAX=1

COPY --from=build /app/bitcoin /opt/bitcoin

RUN useradd -r bitcoin \
  && mkdir -p "/home/bitcoin/.bitcoin" \
  && chmod 700 -R /home/bitcoin \
  && chown -R bitcoin /home/bitcoin
  
USER bitcoin

WORKDIR "/home/bitcoin"

VOLUME ["/home/bitcoin/.bitcoin"]

EXPOSE 8332 8333 18501 18502

CMD ["bitcoind", "-printtoconsole=1", "-debuglogfile=0"]