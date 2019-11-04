FROM drydock.workiva.net/workiva/dart2_base_image:1

WORKDIR /build
ADD pubspec.* /build/
RUN pub get

FROM scratch