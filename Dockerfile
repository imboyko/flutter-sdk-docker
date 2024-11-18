FROM ubuntu:24.04

LABEL description="Image to build Flutter applications for Android"

ARG ANDROID_SDK_TOOLS_VERSION=11076708
ARG ANDROID_SDK_PLATFORM_VERSION=34
ARG ANDROID_SDK_BUILD_TOOLS_VERSION=33.0.1

ARG FLUTTER_SDK_VERSION=3.24.5

ENV ANDROID_HOME=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter

ENV PATH=${PATH}:${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

ENV PUB_CACHE=/var/pub_cache

RUN mkdir -p ${PUB_CACHE}

# Install deps
RUN apt update -y && \
    apt upgrade -y && \
    apt install -y curl git unzip xz-utils zip libglu1-mesa lib32z1 openjdk-17-jdk && \
    apt clean -y

# Install Android cmdtools
RUN curl -L https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -o /tmp/android-sdk-cli.zip && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools && \    
    unzip -d ${ANDROID_HOME}/cmdline-tools /tmp/android-sdk-cli.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools/ ${ANDROID_HOME}/cmdline-tools/latest/ && \
    rm /tmp/android-sdk-cli.zip

RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-${ANDROID_SDK_PLATFORM_VERSION}" "build-tools;${ANDROID_SDK_BUILD_TOOLS_VERSION}"

# Install flutter sdk
RUN curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_SDK_VERSION}-stable.tar.xz | xzcat |  tar -xC /opt/

RUN git config --global --add safe.directory ${FLUTTER_HOME}
RUN flutter doctor --disable-analytics
RUN flutter config --no-cli-animations

WORKDIR /project
