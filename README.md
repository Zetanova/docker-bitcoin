## docker build multiarch 
```
export BITCOIN_VERSION=24.0.1
export BITCOIN_BUILDERS=fanquake laanwj vertion achow101
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --build-arg BITCOIN_VERSION --build-arg BITCOIN_BUILDERS -t zetanova/bitcoin:24.0.1 -t zetanova/bitcoin:latest --push .
```

## docker setup
```
docker volume create --name bitcoin --opt type=none --opt device=/mnt/bigdatadrive/bitcoin --opt o=bind
```

### firewall centos
```
firewall-cmd --permanent --zone=public --add-port=8332/tcp 
firewall-cmd --permanent --zone=public --add-port=8333/tcp
```

## docker run

no rpc
```
docker run -d \
    --name bitcoin \
    --stop-timeout 90 \
    --restart=always \
    --volume bitcoin:/home/bitcoin/.bitcoin \
    -p 8333:8333 \
    zetanova/bitcoin:24.0.1
```

for external rpc client
```
docker run -d \
    --name bitcoin \
    --stop-timeout 90 \
    --restart=always \
    --volume bitcoin:/home/bitcoin/.bitcoin \
    -p 8333:8333 \
    -p 8332:8332 -p 18501:18501 -p 18502:18502 \
    zetanova/bitcoin:24.0.1
```

## bitcoin-cli
`docker exec -it bitcoin bitcoin-cli getmininginfo`