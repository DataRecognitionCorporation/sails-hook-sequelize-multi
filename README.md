# sails-hook-sequelize-multi

This is a fork of the [sails-hook-sequelize](https://github.com/festo/sails-hook-sequelize)
project, expanded to support multiple databases and connections. It's a quick and dirty
implementation.

# Install

Install this hook with:

```sh
$ npm install sails-hook-sequelize-multi --save
```

# Configuration

`.sailsrc`
````
{
  "hooks": {
    "orm": false,
    "pubsub": false
  }
}
```

## Connections files

In the `app/config/connections.js` file, list all the connections that you're going to use.

```javascript
module.exports.connections = {
  staging: {
    user: 'stagingUser'
    password: 'abcd'
    database: 'staging_db'
    options: {
      host: 'staging.example.com'
      dialect: 'mssql'
      pool: {
        max: 5,
        min: 0,
        idle: 1000
      },
      isolationLevel: 'READ UNCOMMITTED'
    }
  },
  production: {
    user: 'prodUser'
    password: 'abcd'
    database: 'production_db'
    options: {
      host: 'prod.example.com'
      dialect: 'mssql'
      pool: {
        max: 5,
        min: 0,
        idle: 1000
      },
      isolationLevel: 'READ UNCOMMITTED'
    }
  }
};
```

## Models config

In the `app/config/models.js` file, declare the model that you'd like to use as the default.
For example to use the `staging` database as the default for the connections file above:

```javascript
module.exports.models = {
  connection: 'staging'
};
```

Or, to use the `production` database as the default:

```javascript
module.exports.models = {
  connection: 'production'
};
```

## Models

No changes to the model code are necessary -- declare the models as you normally do.

## How to use

Initially, all your existing code will work the same as before.
For instance, in the example below

```javascript
UserTable.find(option).then(function(res) {
  // do something
  console(res);
}).catch(function(err) {
  return console(error);
});
```

#License
[MIT](./LICENSE)
