
###############################################################################################
# Go Agent Build
###############################################################################################

FROM golang:1.18-alpine AS agents
ENV GOPROXY=direct

RUN apk add git
# RUN apk add make

WORKDIR /app

COPY . .

# Building Executables
# Mac Build
RUN env GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o exec/datastack-sentinel-darwin-amd64 main.go || true
# Linux Build
RUN env GOOS=linux GOARCH=386 go build -ldflags="-s -w" -o exec/datastack-sentinel-linux-386 main.go
RUN env GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o exec/datastack-sentinel-linux-amd64 main.go || true
# Windows Build
RUN env GOOS=windows GOARCH=386 go build -ldflags="-s -w" -o exec/datastack-sentinel-windows-386-unsigned.exe main.go
RUN env GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o exec/datastack-sentinel-windows-amd64-unsigned.exe main.go


###############################################################################################
#Agent Signing
###############################################################################################

FROM ubuntu:20.04 AS oss

RUN apt-get update
RUN apt-get install -y osslsigncode
RUN apt-get install -y wget

WORKDIR /app

RUN wget --user __signing_key_user__ --password __signing_key_password__ https://cicd.ds.datanimbus.com/agentbuild/out.key
RUN wget --user __signing_key_user__ --password __signing_key_password__ https://cicd.ds.datanimbus.com/agentbuild/cd786349a667ff05-SHA2.pem

COPY --from=agents /app/exec ./exec
COPY --from=agents /app/scriptFiles ./scriptFiles

RUN osslsigncode -h sha2 -certs cd786349a667ff05-SHA2.pem -key out.key -t http://timestamp.comodoca.com/authenticode -in exec/datastack-sentinel-windows-386-unsigned.exe -out exec/datastack-sentinel-windows-386.exe
RUN osslsigncode -h sha2 -certs cd786349a667ff05-SHA2.pem -key out.key -t http://timestamp.comodoca.com/authenticode -in exec/datastack-sentinel-windows-amd64-unsigned.exe -out exec/datastack-sentinel-windows-amd64.exe
