FROM google/dart:1.24.3

WORKDIR /build/
ADD pubspec.yaml /build
RUN pub get
ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch
