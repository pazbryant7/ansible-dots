FROM archlinux:latest

LABEL maintainer="Bryant Paz"

ARG USER=bryant
ARG GROUP=bryant
ARG UID=1000
ARG GID=1000

ENV TZ="America/Merida"

USER ${USER}
USER root

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    sudo \
    curl \
    git \
    gnupg \
    glibc \
    tzdata \
    wget

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN groupadd --gid ${GID} ${GROUP} && \
    useradd --uid ${UID} --gid ${GID} --shell /bin/sh --home /home/${USER} --create-home ${USER} && \
    echo "%${GROUP} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

RUN groupadd docker && \
    usermod -aG docker ${USER}

RUN chown -R ${USER}:${GROUP} /home/${USER}

USER ${USER}

WORKDIR /home/${USER}

COPY --chown=${USER}:${GROUP} bin/dotfiles /home/${USER}/dotfiles

RUN git clone --quiet https://github.com/pazbryant/ansible-dots.git /home/${USER}/.dotfiles
COPY --chown=${USER}:${GROUP} ansible.cfg /home/${USER}/.dotfiles/ansible.cfg

RUN sh "/home/${USER}/dotfiles"
