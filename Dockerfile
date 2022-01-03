# Fix to 3.13.5 due to Python 3.9 incompatibility introduced in Alpine 3.14 and newer (AttributeError: module 'base64' has no attribute 'decodestring')
FROM alpine:3.13.5
LABEL org.opencontainers.image.authors="willisling@live.com"

ENV script_dir="/script"

# Container version serves no real purpose. Increment to force a container rebuild.
ARG container_version="3.13.5.0"
ARG app_dependencies="git python3 py3-pip coreutils tzdata curl py3-certifi py3-cffi py3-cryptography py3-secretstorage py3-jeepney py3-dateutil shadow"
# Fix tzlocal to 2.1 due to Python 3.8 being default in alpine 3.13.5
ARG python_dependencies="pytz tzlocal==2.1 wheel"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR ALPINE ${container_version} *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir ${python_dependencies}

COPY --chmod=0755 docker-init.sh /usr/local/bin/docker-init.sh
  
VOLUME "${script_dir}"

CMD /usr/local/bin/docker-init.sh