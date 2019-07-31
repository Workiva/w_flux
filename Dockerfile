FROM google/dart:2.4 as dart2

WORKDIR /build
ADD pubspec.* /build/
RUN pub get

FROM scratch