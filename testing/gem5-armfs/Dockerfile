# syntax=docker/dockerfile:1.7
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git m4 scons python3-dev python3-pip \
    zlib1g zlib1g-dev libprotobuf-dev protobuf-compiler libprotoc-dev \
    libgoogle-perftools-dev libboost-all-dev pkg-config \
    wget ca-certificates curl xz-utils bzip2 file \
    && rm -rf /var/lib/apt/lists/*

# Get gem5 (stable) and build ARM FS binary
WORKDIR /opt
RUN git clone https://github.com/gem5/gem5.git && \
    cd gem5 && \
    git checkout stable && \
    scons -j$(nproc) build/ARM/gem5.opt  # ARM ISA binary
# Docs: building & deps on Ubuntu 22.04. [4](https://www.gem5.org/documentation/general_docs/building)

# Add a non-root user for convenience
ARG USER=dev UID=1000 GID=1000
RUN groupadd -g $GID $USER && useradd -m -u $UID -g $GID -s /bin/bash $USER

# Workspace + assets inside container
RUN mkdir -p /work /assets /runs && chown -R $USER:$USER /work /assets /runs
USER $USER
WORKDIR /work

# Small Python helper libs for parsing/plots (optional)
RUN pip3 install --user pandas matplotlib

# Default to bash
CMD ["/bin/bash"]
