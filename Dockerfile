FROM google/dart:2.13.4
WORKDIR /build
ADD pubspec.yaml /build
RUN pub get
FROM scratch
