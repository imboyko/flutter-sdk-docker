FROM scratch AS distr

ARG ANDROID_SDK_TOOLS_VERSION=11076708 
ARG FLUTTER_SDK_VERSION=3.24.5

ADD https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip /distr/cmdline-tools.zip
ADD https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_SDK_VERSION}-stable.tar.xz /distr/flutter.tar.xz

FROM ubuntu:24.04 AS installer

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update -y && apt install --no-install-recommends -y unzip xz-utils

RUN --mount=from=distr,source=/distr,target=/distr mkdir -p /cmdline-tools && unzip -d /cmdline-tools /distr/cmdline-tools.zip
RUN --mount=from=distr,source=/distr,target=/distr mkdir -p /flutter &&  tar -xC /flutter -f /distr/flutter.tar.xz

FROM ubuntu:24.04

LABEL description="Image to build Flutter applications for Android"

ARG ANDROID_SDK_PLATFORM_VERSION=34
ARG ANDROID_SDK_BUILD_TOOLS_VERSION=33.0.1

# Install deps
RUN --mount=type=tmpfs,target=/tmp \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update -y && apt install --no-install-recommends -y git libglu1-mesa lib32z1 openjdk-17-jdk

ENV ANDROID_HOME=/opt/android-sdk FLUTTER_HOME=/opt/flutter

ENV PATH=${PATH}:${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Install Android cmdline-tools
COPY --from=installer /cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/

RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-${ANDROID_SDK_PLATFORM_VERSION}" "build-tools;${ANDROID_SDK_BUILD_TOOLS_VERSION}"

# Install flutter sdk
# TODO clean flutter dir
COPY --from=installer /flutter/* ${FLUTTER_HOME}/

RUN flutter doctor --disable-analytics && \
    flutter config --no-cli-animations
