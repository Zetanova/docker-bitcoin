FROM ubuntu:22.04 as build
ARG TARGETPLATFORM
ARG BITCOIN_VERSION
ARG BITCOIN_BUILDERS=fanquake laanwj vertion achow101

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN if [ "${TARGETPLATFORM}" = "linux/amd64" ] || [ "${TARGETPLATFORM}" = "" ]; then export BITCOIN_TARGET=x86_64-linux-gnu; fi \
  && if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then export BITCOIN_TARGET=aarch64-linux-gnu; fi \
  && if [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then export BITCOIN_TARGET=arm-linux-gnueabihf; fi \
  && echo "bitcoin-${BITCOIN_VERSION}-${BITCOIN_TARGET}" \
  && curl -SLO "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${BITCOIN_TARGET}.tar.gz" \
  && curl -SLO "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS" \
  && grep " bitcoin-${BITCOIN_VERSION}-${BITCOIN_TARGET}.tar.gz\$" SHA256SUMS | sha256sum -c \
  && curl -SLO "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc"

#import all builder keys
RUN curl -SLO "https://raw.githubusercontent.com/bitcoin/bitcoin/v${BITCOIN_VERSION}/contrib/builder-keys/keys.txt" \
  && while read fingerprint keyholder_name; do gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys ${fingerprint}; done < ./keys.txt \
  && while read fingerprint keyholder_name; do gpg --keyserver hkps://keys.openpgp.org --recv-keys ${fingerprint}; done < ./keys.txt

RUN gpg --refresh-keys \
  && echo ${BITCOIN_BUILDERS} | while read builder; do \
  echo "builder ${builder} verification" \
  &&curl -SLO https://raw.githubusercontent.com/bitcoin-core/guix.sigs/main/${BITCOIN_VERSION}/${builder}/all.SHA256SUMS.asc \
  && gpg --verify all.SHA256SUMS.asc SHA256SUMS \
  && rm all.SHA256SUMS.asc; \
  done

RUN tar -xzf *.tar.gz -C . \
  && rm *.tar.gz *.asc \
  && rm -rf ./bitcoin-${BITCOIN_VERSION}/bin/bitcoin-qt \
  && mv ./bitcoin-${BITCOIN_VERSION} ./bitcoin

FROM ubuntu:22.04

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