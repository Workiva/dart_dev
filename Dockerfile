FROM dart:2.18.7
WORKDIR /build
ADD pubspec.yaml /build
RUN dart pub get
FROM scratch
