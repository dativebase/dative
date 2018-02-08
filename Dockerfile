FROM node:8

# Install Bower & Grunt
RUN npm install -g bower grunt-cli && \
    echo '{ "allow_root": true }' > /root/.bowerrc

COPY . /usr/src/dative
ENV GIT_DIR=/usr/src/dative

WORKDIR /usr/src/dative/
RUN npm install
RUN bower install
WORKDIR /usr/src/dative/test/
RUN bower install

WORKDIR /usr/src/dative/
CMD grunt serve
