ARG ALPINE_VERSION=3.18.0
#ARG PACKER_VERSION=1.8.0-r3
#ARG ANSIBLE_CORE_VERSION=2.13.0-r0
#ARG JQ_VERSION=1.6-r1
ARG UID=1000
ARG GID=1000

FROM alpine:$ALPINE_VERSION
ARG PACKER_VERSION
ARG ANSIBLE_CORE_VERSION
ARG JQ_VERSION
ARG UID
ARG GID

RUN apk add --no-cache ansible-core packer jq

RUN adduser ansible -u "$UID" -D -h /home/ansible "$GID"

RUN mkdir -p /configs /manifests /cache \
    && chown ansible /manifests /configs /cache

USER ansible
WORKDIR /home/ansible
COPY default.json                   default.json
COPY alpine.pkr.hcl                 alpine.pkr.hcl
COPY playbook.yml                   playbook.yml
COPY --chmod=u=rx,og= entrypoint.sh entrypoint.sh

VOLUME /cache

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
CMD ["default.json"]

LABEL "dev.pius.alpine-on-hetzner.alpine.version"=$ALPINE_VERSION
#LABEL "dev.pius.alpine-on-hetzner.pkgs.ansible-core.version"=$ANSIBLE_CORE_VERSION
#LABEL "dev.pius.alpine-on-hetzner.pkgs.packer.version"=$PACKER_VERSION
#LABEL "dev.pius.alpine-on-hetzner.pkgs.jq.version"=$JQ_VERSION
