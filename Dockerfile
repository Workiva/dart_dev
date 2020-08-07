FROM google/dart:2.5
WORKDIR /build
ADD pubspec.yaml /build
RUN pub get
FROM scratch
