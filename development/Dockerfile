# syntax=docker/dockerfile:1.7

# Cortex-A7 is ARMv7-A → Debian armhf
FROM --platform=linux/arm/v7 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gdb \
    clang \
    lldb \
    cmake \
    ninja-build \
    pkg-config \
    git \
    ca-certificates \
    curl \
    wget \
    file \
    binutils \
    vim \
    nano \
    locales \
 && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ARG USER=dev
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID $USER \
 && useradd -m -u $UID -g $GID -s /bin/bash $USER

WORKDIR /work
USER $USER

CMD ["/bin/bash"]