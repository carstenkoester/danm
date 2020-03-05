FROM alpine:latest AS builder
MAINTAINER Levente Kale <levente.kale@nokia.com>

ARG VERSION
ARG BUILD_TAG

ENV GOPATH=/go
ENV GOROOT=/usr/local/go
ENV PATH ${GOPATH}/bin:/usr/local/go/bin:$PATH
ENV GO_VERSION 1.12.9
ENV GOOS linux
ENV CGO_ENABLED 0
ENV GOARCH amd64

RUN apk add --no-cache ca-certificates \
 && apk update --no-cache \
 && apk upgrade --no-cache \
 && apk add --no-cache make gcc musl-dev glide git bash curl tar \
 && mkdir -p ${GOPATH} \
 && mkdir -p ${GOROOT} \
 && mkdir -p ${GOPATH}/bin \
 && mkdir -p ${GOPATH}/src \
 && curl -fsSL -k https://dl.google.com/go/go${GO_VERSION}.src.tar.gz | tar zx --strip-components=1 -C ${GOROOT} \
 && cd ${GOROOT}/src/ \
 && ./make.bash \
 && rm -rf /var/cache/apk/* \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/*

RUN mkdir -p ${GOPATH}/src/github.com/nokia
COPY / ${GOPATH}/src/github.com/nokia/danm

WORKDIR ${GOPATH}/src/github.com/nokia/danm

RUN glide install --strip-vendor \
 && go get -d github.com/vishvananda/netlink \
 && go get github.com/containernetworking/plugins/pkg/ns \
 && go get github.com/golang/groupcache/lru

RUN go install -a -ldflags "-extldflags '-static' -X main.version=${BUILD_TAG} -X main.commitHash=${VERSION}" github.com/nokia/danm/cmd/danm \
 && go install -a -ldflags "-extldflags '-static' -X main.version=${BUILD_TAG} -X main.commitHash=${VERSION}" github.com/nokia/danm/cmd/netwatcher \
 && go install -a -ldflags "-extldflags '-static' -X main.version=${BUILD_TAG} -X main.commitHash=${VERSION}" github.com/nokia/danm/cmd/svcwatcher \
 && go install -a -ldflags "-extldflags '-static' -X main.version=${BUILD_TAG} -X main.commitHash=${VERSION}" github.com/nokia/danm/cmd/webhook \
 && go install -a -ldflags "-extldflags '-static'" github.com/nokia/danm/cmd/fakeipam \
 && go install -a -ldflags "-extldflags '-static'" github.com/nokia/danm/cmd/cnitest \
 && go install -a -ldflags "-extldflags '-static'" github.com/containernetworking/plugins/plugins/main/macvlan



FROM alpine:latest AS netwatcher
MAINTAINER Levente Kale <levente.kale@nokia.com>

COPY --from=builder /go/bin/netwatcher /usr/local/bin/netwatcher

RUN apk add --no-cache --virtual .tools curl libcap iputils  \
 && adduser -u 147 -D -H -s /sbin/nologin danm \
 && chown root:danm /usr/local/bin/netwatcher \
 && chmod 750 /usr/local/bin/netwatcher \
 && setcap cap_sys_ptrace,cap_sys_admin,cap_net_admin=eip /usr/local/bin/netwatcher \
 && setcap cap_net_raw=eip /usr/sbin/arping \
 && apk del .tools

USER danm

WORKDIR /
ENTRYPOINT ["/usr/local/bin/netwatcher"]



FROM alpine:latest AS svcwatcher
MAINTAINER Levente Kale <levente.kale@nokia.com>

COPY --from=builder /go/bin/svcwatcher /usr/local/bin/svcwatcher

RUN apk add --no-cache --virtual .tools curl libcap iputils  \
 && adduser -u 147 -D -H -s /sbin/nologin danm \
 && chown root:danm /usr/local/bin/svcwatcher \
 && chmod 750 /usr/local/bin/svcwatcher \
 && apk del .tools

USER danm

WORKDIR /
ENTRYPOINT ["/usr/local/bin/svcwatcher"]



FROM alpine:latest AS webhook
MAINTAINER Levente Kale <levente.kale@nokia.com>

COPY --from=builder /go/bin/webhook /usr/local/bin/webhook

RUN apk add --no-cache --virtual .tools curl libcap iputils  \
 && adduser -u 147 -D -H -s /sbin/nologin danm \
 && chown root:danm /usr/local/bin/webhook \
 && chmod 750 /usr/local/bin/webhook \
 && apk del .tools

USER danm

WORKDIR /

ENTRYPOINT ["/usr/local/bin/webhook"]




FROM alpine:latest AS danmcni

VOLUME ["/cni"]

RUN mkdir /cnibin

COPY --from=builder /go/bin/danm /cnibin/danm
COPY --from=builder /go/bin/fakeipam /cnibin/fakeipam
COPY --from=builder /go/bin/macvlan /cnibin/macvlan

CMD [ "sh", "-c", "cp -fa /cnibin/* /cni/ && sleep infinity" ]
