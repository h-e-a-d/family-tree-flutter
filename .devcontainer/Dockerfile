FROM debian:bullseye-slim

# Install required packages
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
    apt-get clean

# Install Flutter SDK
ENV FLUTTER_VERSION=3.22.1
RUN git clone https://github.com/flutter/flutter.git /opt/flutter -b stable \
    && /opt/flutter/bin/flutter doctor

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-download dependencies to speed up flutter doctor
RUN flutter doctor

# Enable web support
RUN flutter config --enable-web
