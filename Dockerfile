FROM library/node:0.10

# Install Bower & Grunt
RUN npm install -g bower grunt-cli && \
    echo '{ "allow_root": true }' > /root/.bowerrc

ADD Gruntfile.coffee /usr/src/dative/Gruntfile.coffee
ADD UnicodeData.json /usr/src/dative/UnicodeData.json
ADD UnicodeData.txt /usr/src/dative/UnicodeData.txt
ADD app /usr/src/dative/app
ADD bower.json /usr/src/dative/bower.json
ADD favicon.png /usr/src/dative/favicon.png
ADD package.json /usr/src/dative/package.json
ADD scripts /usr/src/dative/scripts
ADD servers.json /usr/src/dative/servers.json
ADD test /usr/src/dative/test

WORKDIR /usr/src/dative/
RUN npm install
RUN bower install
WORKDIR /usr/src/dative/test/
RUN bower install

WORKDIR /usr/src/dative/
CMD ["grunt" "serve"]
