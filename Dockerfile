ARG ALPINE_VERSION=3.15.0
ARG PACKER_VERSION=1.7.8-r1
ARG ANSIBLE_VERSION=4.8.0-r0
ARG JQ_VERSION=1.6-r1
ARG UID=1000
ARG GID=1000

FROM alpine:$ALPINE_VERSION
ARG PACKER_VERSION
ARG ANSIBLE_VERSION
ARG JQ_VERSION
ARG UID
ARG GID

RUN apk add --no-cache          \
    ansible=$ANSIBLE_VERSION    \
    packer=$PACKER_VERSION      \
    jq=$JQ_VERSION

RUN adduser ansible -u "$UID" -D -h /home/ansible

USER ansible:"$GID"
WORKDIR /home/ansible
COPY default.json                   default.json
COPY alpine.pkr.hcl                 alpine.pkr.hcl
COPY playbook.yml                   playbook.yml
COPY --chmod=u=rx,og= entrypoint.sh entrypoint.sh

VOLUME /cache

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
CMD ["default.json"]

LABEL "alpine.pius.dev/alpine-version"=$ALPINE_VERSION
LABEL "alpine.pius.dev/ansible/version"=$ANSIBLE_VERSION
LABEL "alpine.pius.dev/packer/version"=$PACKER_VERSION
LABEL "alpine.pius.dev/jq/version"=$JQ_VERSION