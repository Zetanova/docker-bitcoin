## docker build multiarch 
```
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t bitcoin:latest --push .
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
```
docker run -it -d \
    --name bitcoin \
    --restart=always \
    --volume bitcoin:/home/bitcoin/.bitcoin \
    -p 8333:8333 \
    zetanova/bitcoin:0.20.0
```

## bitcoin-cli
`docker exec -it bitcoin bitcoin-cli getmininginfo`