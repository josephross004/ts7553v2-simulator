# syntax=docker/dockerfile:1.7
FROM --platform=linux/arm/v7 debian:bookworm-slim

# 1. Define ARGs at the top so they are available to all RUN commands
ARG USER=dev
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# 2. Install everything as ROOT
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gdb clang lldb cmake ninja-build pkg-config \
    git ca-certificates curl wget file binutils \
    vim nano locales \
    # Python basics
    python3 python3-pip python3.11-venv python3-dev \
    # --- ADDED DEPENDENCIES FOR ACOUSTIC SURVEY ---
    # Image support (Pillow/Matplotlib)
    libopenjp2-7 libtiff6 libjpeg62-turbo-dev \
    # Graphics/Display (Matplotlib X11 support)
    libxcb1 libx11-6 \
    # Audio support (Soundfile backend)
    libsndfile1 \
    # Data format support (HDF5)
    libhdf5-serial-dev \
    # ----------------------------------------------
    # ARM-friendly SciPy and math libs
    python3-scipy libopenblas-dev \
    # Sudo setup
    sudo \
 && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen \
 # 3. User setup
 && groupadd -g $GID $USER \
 && useradd -m -u $UID -g $GID -s /bin/bash $USER \
 && echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER \
 && chmod 0440 /etc/sudoers.d/$USER \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

WORKDIR /work

# 4. Switch to the user AFTER all root tasks are done
USER $USER

# 5. Create a virtual environment that inherits the system SciPy
# This is crucial for ARM so you don't have to re-compile SciPy/NumPy via pip
RUN python3 -m venv --system-site-packages /home/$USER/venv
ENV PATH="/home/$USER/venv/bin:$PATH"

# Ensure Matplotlib uses a non-interactive backend by default (preventing X11 errors)
ENV MPLBACKEND=Agg

CMD ["/bin/bash"]