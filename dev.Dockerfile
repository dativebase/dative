FROM node:8

RUN npm install -g bower grunt-cli && \
    echo '{ "allow_root": true }' > /root/.bowerrc

RUN mkdir -p /usr/src/dative
ENV GIT_DIR=/usr/src/dative
WORKDIR /usr/src/dative

COPY Gruntfile.coffee /usr/src/dative/Gruntfile.coffee 
COPY bower.json /usr/src/dative/bower.json 
COPY package-lock.json /usr/src/dative/package-lock.json 
COPY package.json /usr/src/dative/package.json 

RUN npm install
RUN bower install

COPY . /usr/src/dative
RUN grunt build