FROM google/dart:2.7.2
WORKDIR /build
ADD pubspec.yaml /build
RUN pub get
FROM scratch
