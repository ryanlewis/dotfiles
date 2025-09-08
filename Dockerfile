# Minimal Dockerfile for testing dotfiles installation
FROM ubuntu:24.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies needed for the install script
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    build-essential \
    software-properties-common \
    locales \
    ca-certificates \
    gnupg \
    lsb-release \
    # Additional tools that might be needed
    unzip \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a non-root user for testing
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Set up environment
ENV USER=testuser
ENV HOME=/home/testuser
ENV TERM=xterm-256color

# Create dev directory
RUN mkdir -p /home/testuser/dev

# Default command - bash shell (will switch to fish after install)
CMD ["/bin/bash"]