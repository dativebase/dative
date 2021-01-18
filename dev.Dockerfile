FROM node:8

RUN npm install -g grunt-cli && \
    echo '{ "allow_root": true }' > /root/.bowerrc

RUN mkdir -p /usr/src/dative/test
ENV GIT_DIR=/usr/src/dative

COPY package.json /usr/src/dative/package.json
COPY yarn.lock /usr/src/dative/yarn.lock
COPY test/package.json /usr/src/dative/test/package.json
COPY test/yarn.lock /usr/src/dative/test/yarn.lock

WORKDIR /usr/src/dative/
RUN yarn
WORKDIR /usr/src/dative/test/
RUN yarn

COPY . /usr/src/dative
WORKDIR /usr/src/dative/
RUN grunt build
