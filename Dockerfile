FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang git make && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
COPY . /go/src/github.com/opensourceways/xihe-sync-repo
WORKDIR /go/src/github.com/opensourceways/xihe-sync-repo
RUN GO111MODULE=on CGO_ENABLED=0 go build -o xihe-sync-repo -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'"
RUN tar -xf ./app/tools/obsutil.tar.gz
RUN git clone https://github.com/git-lfs/git-lfs.git -b v3.4.0 && \
    cd git-lfs && \
    make

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow git bash && \
    groupadd -g 5000 mindspore && \
    useradd -u 5000 -g mindspore -s /bin/bash -m mindspore

COPY  --chown=root --chmod=555 --from=BUILDER /go/src/github.com/opensourceways/xihe-sync-repo/git-lfs/bin/git-lfs /usr/local/bin/git-lfs

USER mindspore
WORKDIR /opt/app

COPY --chown=mindspore:mindspore --from=BUILDER /go/src/github.com/opensourceways/xihe-sync-repo/xihe-sync-repo /opt/app
COPY --chown=mindspore:mindspore --from=BUILDER /go/src/github.com/opensourceways/xihe-sync-repo/obsutil /opt/app
COPY --chown=mindspore:mindspore --from=BUILDER /go/src/github.com/opensourceways/xihe-sync-repo/app/tools/sync_files.sh /opt/app

RUN chmod 550 /opt/app/xihe-sync-repo
RUN chmod 550 /opt/app/obsutil
RUN chmod 550 /opt/app/sync_files.sh
RUN git lfs install

RUN mkdir /opt/app/workspace

ENTRYPOINT ["/opt/app/xihe-sync-repo"]
