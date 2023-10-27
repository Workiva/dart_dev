FROM dart:2.19.6
WORKDIR /build
ADD pubspec.yaml /build
RUN dart pub get
FROM scratch
