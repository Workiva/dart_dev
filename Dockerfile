FROM google/dart:2.13.4
WORKDIR /build
ADD pubspec.yaml /build
RUN dart pub get
FROM scratch
