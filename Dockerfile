FROM drydock-prod.workiva.net/workiva/dart2_base_image:0.0.0-dart2.13.4

WORKDIR /build
ADD pubspec.* /build/
RUN pub get

FROM scratch