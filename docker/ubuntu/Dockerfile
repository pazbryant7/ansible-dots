FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  sudo \
  software-properties-common \
  && add-apt-repository --yes --update ppa:ansible/ansible \
  && apt-get install -y --no-install-recommends ansible \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ARG TEST_USER=testuser
RUN useradd -m -s /bin/sh -G sudo "${TEST_USER}" \
  && echo "${TEST_USER} ALL=(ALL) NOPASSWD: ALL" \
  > /etc/sudoers.d/testuser \
  && chmod 440 /etc/sudoers.d/testuser

WORKDIR /ansible

ARG DISTRO=ubuntu

COPY requirements/ requirements/

RUN ansible-galaxy collection install -r requirements/common.yml \
 && ansible-galaxy collection install -r requirements/${DISTRO}.yml

RUN mkdir -p .secrets && chmod 700 .secrets

USER ${TEST_USER}

CMD ["/bin/sh"]
