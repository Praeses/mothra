# Mothra
## inventory management made cool!

### To install
    npm install

### To run server

    coffee server.coffee

Things that still need to be done.

1. Sass installation needs to be completed
2. Jasmine testing framework needs to be installed for ( added )
  1. node.js
  2. standalone (for server side testing)
3. Actual html needs to be added to index
4. Faye needs to be installed, AND IT SUPPORTS REDIS OUT OF THE BOX WOOT!! (**UPDATE: done** )

Possible tasks

1. rvm? at this point we will only have one gem (**UPDATE: using npm 1.0 package system**)
2. mockups of functionality to make development easier

### Redis pub/sub working
  To Demo:

  coffee server.coffee # => this will start the node server

  redis-cli # => redis console

  publish live "super cool message"
