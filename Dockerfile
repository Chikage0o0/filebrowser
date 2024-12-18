FROM node:18 AS node_build
WORKDIR /go/src/github.com/filebrowser/
ENV VERSION=v2.31.2
RUN git clone --depth=1 https://github.com/filebrowser/filebrowser.git  -b ${VERSION}  filebrowser
WORKDIR /go/src/github.com/filebrowser/filebrowser/
RUN cd frontend && npm ci && npm run build


FROM golang:alpine AS go_build

COPY --from=node_build /go/src/github.com/filebrowser/filebrowser/ /go/src/github.com/filebrowser/filebrowser/
ENV GO111MODULE=on
ENV CGO_ENABLED=1
RUN apk add --no-cache gcc musl-dev git bash
COPY ./patches /patches
WORKDIR /go/src/github.com/filebrowser/filebrowser/
RUN git apply /patches/*.patch
RUN MODULE=$(go list -m) VERSION=$(git describe --tags 2>/dev/null || git rev-parse --abbrev-ref HEAD) VERSION_HASH=$(git rev-parse HEAD) && \
    go build -ldflags "-s -w -X \"${MODULE}/version.Version=${VERSION}\" -X \"${MODULE}/version.CommitSHA=${VERSION_HASH}\"" -o . && \
    mkdir /opt/filebrowser/ && \
    mv /go/src/github.com/filebrowser/filebrowser/filebrowser /opt/filebrowser/ 

FROM alpine:3

# 拷贝可执行文件
WORKDIR /opt/filebrowser/
COPY entrypoint.sh /usr/bin
COPY --from=go_build /opt/filebrowser/ /opt/filebrowser/

# 定义环境变量
ENV TZ=Asia/Shanghai

# 添加用户&& 设置时区
RUN addgroup --gid 1000 filebrowser && \
    adduser --uid 1000 --ingroup filebrowser --disabled-password filebrowser && \
    apk add --no-cache ca-certificates su-exec tzdata && \
    chown -R filebrowser:filebrowser /opt/filebrowser/ && \
    chmod 755 /usr/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
