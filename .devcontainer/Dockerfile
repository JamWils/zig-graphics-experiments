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

# Install Dear ImGui
ENV IMGUI_VERSION=1.90.4
RUN cd /tmp && \
    curl -L -O https://github.com/ocornut/imgui/archive/refs/tags/v${IMGUI_VERSION}.tar.gz && \
    tar -xvzf v${IMGUI_VERSION}.tar.gz && \
    rm v${IMGUI_VERSION}.tar.gz && \
    mv imgui-${IMGUI_VERSION} /opt/imgui-${IMGUI_VERSION}

# Install CImGui
ENV CIMGUI_VERSION=1.53.1
RUN cd /tmp && \
    curl -L -O https://github.com/cimgui/cimgui/archive/refs/tags/v${CIMGUI_VERSION}.tar.gz && \
    tar -xvzf v${CIMGUI_VERSION}.tar.gz && \
    rm v${CIMGUI_VERSION}.tar.gz && \
    mv cimgui-${CIMGUI_VERSION} /opt/cimgui-${CIMGUI_VERSION}

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

# Install Flecs
# https://github.com/SanderMertens/flecs/archive/refs/tags/v3.2.11.tar.gz
ENV FLECS_VERSION=3.2.7
RUN cd /tmp && \
    curl -L -O https://github.com/SanderMertens/flecs/archive/refs/tags/v${FLECS_VERSION}.tar.gz && \
    ls -l && \
    tar -xvzf v${FLECS_VERSION}.tar.gz && \
    rm v${FLECS_VERSION}.tar.gz && \
    mv flecs-${FLECS_VERSION} /opt/flecs-${FLECS_VERSION}

# Install Zig
RUN ZIG_VERSION=0.12.0-dev.2805+79e99c401 && \
    curl -L -o zig-linux-x86_64-${ZIG_VERSION}.tar.xz https://ziglang.org/builds/zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
    tar -Jxf zig-linux-x86_64-${ZIG_VERSION}.tar.xz -C /usr/local/bin --strip-components=1 && \
    rm zig-linux-x86_64-${ZIG_VERSION}.tar.xz

# Set the entry point to bash
CMD ["/bin/bash"]
