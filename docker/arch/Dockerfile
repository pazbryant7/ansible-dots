FROM archlinux:base

RUN pacman -Syu --noconfirm \
  && pacman -S --noconfirm python sudo ansible \
  && pacman -Scc --noconfirm

ARG TEST_USER=testuser

RUN useradd -m -s /bin/sh -G wheel "${TEST_USER}" \
  && echo "${TEST_USER} ALL=(ALL) NOPASSWD: ALL" \
  > /etc/sudoers.d/testuser \
  && chmod 440 /etc/sudoers.d/testuser

USER ${TEST_USER}

WORKDIR /ansible

ARG DISTRO=arch

COPY --chown=${TEST_USER} requirements/ requirements/

RUN ansible-galaxy collection install -r requirements/common.yml \
  && ansible-galaxy collection install -r requirements/${DISTRO}.yml

RUN mkdir -p .secrets && chmod 700 .secrets

CMD ["/bin/sh"]
