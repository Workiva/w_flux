FROM google/dart:1.24.3 as dart1

WORKDIR /build

ADD pubspec.* /build/
RUN pub get

FROM google/dart:2.0.0 as dart2

WORKDIR /build

ADD pubspec.* /build/
RUN pub get

ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch