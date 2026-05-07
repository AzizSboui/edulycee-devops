FROM ubuntu:22.04

RUN apt update && apt install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    nginx

RUN git clone https://github.com/flutter/flutter.git -b stable /flutter

ENV PATH="$PATH:/flutter/bin"

RUN flutter doctor

WORKDIR /app

COPY . .

RUN flutter pub get

RUN flutter build web

RUN rm -rf /var/www/html/*

RUN cp -r build/web/* /var/www/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
