FROM --platform=linux/amd64 redhat/ubi9-minimal:latest AS builder

ARG RUNTIMEUSER=1001

ENV ARTIFACT_JAR_PATTERN=*-exec.jar
ENV MAIN_CLASS=io.netty.nat.test.NettyNativeTestApplication
ENV BINARY_NAME=nettytest

# LINUX
ENV NIK_TAR_GZ=bellsoft-liberica-vm-openjdk23+38-24.1.0+1-linux-amd64.tar.gz
ENV NIK_DOWNLOAD_URL=https://github.com/bell-sw/LibericaNIK/releases/download/24.1.0%2B1-23%2B38/${NIK_TAR_GZ}
ENV NIK_FOLDER=bellsoft-liberica-vm-openjdk23-24.1.0
ENV NIK_CHECKSUM=b96014c458a45ca8972698ea2b706d480d24bbe4

USER root

WORKDIR /Library/Java/LibericaNativeImageKit/

# Install required tools and download Liberica Native Image Kit
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y tar g++ make zlib-devel gzip findutils && \
    microdnf clean all && \
    mkdir -p /Library/Java/LibericaNativeImageKit/ && \
    curl -OL ${NIK_DOWNLOAD_URL} && \
    echo "'$(sha1sum ${NIK_TAR_GZ})' checked against '${NIK_CHECKSUM}  ${NIK_TAR_GZ}'" && \
    if [ $(sha1sum ${NIK_TAR_GZ}) != `echo ${NIK_CHECKSUM}  ${NIK_TAR_GZ}` ]; then exit 1; fi && \
    tar -zxvf ./${NIK_TAR_GZ} && \
    rm ./${NIK_TAR_GZ} && \
    mkdir -p /native-image-build/

ENV NIK_HOME=/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/
ENV JAVA_HOME=/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/
ENV PATH="$PATH:/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/bin/"

# Build native image
COPY ./target/${ARTIFACT_JAR_PATTERN} ./InitializeAtBuildTime ./InitializeAtRunTime /native-image-build/
WORKDIR /native-image-build/
RUN jar -xvf ${ARTIFACT_JAR_PATTERN} && \
    native-image \
    --no-fallback \
    -march=native \
    -Djavax.net.ssl.trustStore=/etc/pki/ca-trust/extracted/java/cacerts \
    --initialize-at-build-time=$(tr '\n' ',' < ./InitializeAtBuildTime) \
    --initialize-at-run-time=$(tr '\n' ',' < ./InitializeAtRunTime) \
    --enable-https \
    --enable-url-protocols=https \
    --install-exit-handlers \
    -cp .:BOOT-INF/classes:$(find BOOT-INF/lib | tr '\n' ':') ${MAIN_CLASS} \
    -o ${BINARY_NAME}

# Create the final runtime image
FROM --platform=linux/amd64 redhat/ubi9-minimal:latest

ARG RUNTIMEUSER=1001

ENV BINARY_NAME=nettytest

USER root

# Copy the native image from the builder stage
COPY --from=builder /native-image-build/${BINARY_NAME} /native-image/

WORKDIR /native-image/

USER ${RUNTIMEUSER}

ENTRYPOINT [ "bash", "-c", "/native-image/${BINARY_NAME}"]