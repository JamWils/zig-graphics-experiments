# Start from the latest Alpine base image
FROM alpine:3.19.1

# Set work directory
WORKDIR /root

# Install build dependencies and basic tools
RUN apk update && apk add --no-cache \
    build-base \
    cmake \
    curl \
    git \
    zip \
    unzip \
    tar \
    xz \
    bash

# Install Vulkan SDK
ENV VULKAN_SDK_VERSION=1.3.275.0 
RUN cd /tmp && \
    curl -L -O https://sdk.lunarg.com/sdk/download/${VULKAN_SDK_VERSION}/linux/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.xz && \
    tar -xvf vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.xz && \
    rm vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.xz && \
    mv ${VULKAN_SDK_VERSION} /opt/vulkansdk-${VULKAN_SDK_VERSION}

ENV VULKAN_SDK="/opt/vulkansdk-${VULKAN_SDK_VERSION}/x86_64"
ENV PATH="${VULKAN_SDK}/bin:$PATH"
ENV LD_LIBRARY_PATH="${VULKAN_SDK}/lib:$LD_LIBRARY_PATH"
ENV VK_LAYER_PATH="${VULKAN_SDK}/etc/vulkan/explicit_layer.d"

# Install Zig
RUN ZIG_VERSION=0.12.0-dev.2805+79e99c401 && \
    curl -L -o zig-linux-x86_64-${ZIG_VERSION}.tar.xz https://ziglang.org/builds/zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
    tar -Jxf zig-linux-x86_64-${ZIG_VERSION}.tar.xz -C /usr/local/bin --strip-components=1 && \
    rm zig-linux-x86_64-${ZIG_VERSION}.tar.xz

# Set the entry point to bash
CMD ["/bin/bash"]
