FROM ghcr.io/void-linux/void-glibc:latest

RUN xbps-install -Syu \
  && xbps-install -y python3 sudo ansible shadow \
  && rm -rf /var/cache/xbps/*

ARG TEST_USER=testuser

RUN useradd -m -s /bin/sh -G wheel "${TEST_USER}" \
  && echo "${TEST_USER} ALL=(ALL) NOPASSWD: ALL" \
  > /etc/sudoers.d/testuser \
  && chmod 440 /etc/sudoers.d/testuser

USER ${TEST_USER}

WORKDIR /ansible

# Set default to void so it pulls the correct requirements file
ARG DISTRO=void

COPY --chown=${TEST_USER} requirements/ requirements/

RUN ansible-galaxy collection install -r requirements/common.yml \
  && ansible-galaxy collection install -r requirements/${DISTRO}.yml

RUN mkdir -p .secrets && chmod 700 .secrets

CMD ["/bin/sh"]
