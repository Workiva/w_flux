FROM drydock-prod.workiva.net/workiva/dart2_base_image:1

WORKDIR /build
ADD pubspec.* /build/
RUN dart pub get

FROM scratch