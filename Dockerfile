#FROM drydock-prod.workiva.net/workiva/dart2_base_image:1
FROM docker.workiva.net/workiva/dart2_base_image:latest

WORKDIR /build
ADD pubspec.* /build/
RUN dart pub get
RUN create_publishable_artifact.sh

FROM scratch