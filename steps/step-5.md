# Step 5 - Security Configuration

We will start by configuring `cbsecurity` so we can secure our app and be able to provide Json Web Tokens (JWT) for securing our app.  Once the configuration is done, we will move on to start the user registration process.

- Go over cbSecurity
- Go over cbAuth
- Go over JWT

Let's go over the configuration by opening the [config/modules/cbsecurity.cfc](../src/config/modules/cbsecurity.cfc) file.  Let's do the following changes:

- Add storage of our JWT tokents to the database
- Enable firewall logging, if not the visualizer doesn't work
- Enable the security visualizer

All of these changes are done in the `jwt` struct of the configuration file.

```javascript

firewal : {
    // Firewall database event logs.
    "logs"                        : {
        "enabled"    : true,
        "dsn"        : "cms",
        "schema"     : "",
        "table"      : "cbsecurity_logs",
        "autoCreate" : true
    },
},

jwt : {
    // Token Storage
    tokenStorage               : {
        // enable or not, default is true
        "enabled"    : true,
        // A cache key prefix to use when storing the tokens
        "keyPrefix"  : "cbjwt_",
        // The driver to use: db, cachebox or a WireBox ID
        "driver"     : "db",
        // Driver specific properties
        "properties" : { table : "cbjwt" }
    }
}

visualizer : {
    "enabled"      : true,
    "secured"      : false,
    "securityRule" : {}
},
```

> We will secure the visualizer later. Also note that we won't be using refresh tokens this time around.

## JWT Secret Key

Let's add the JWT Secret now, let's begin by generating a secret key. Go to CommandBox and let's generate one:

```bash
#generateSecretKey blowfish 256

>/TvWsL6k2Ap2/wbDroYmM9WT5JF/PndOdlzpJQEqUuI=
```

Please note that this is not necessary in the latest version of cbSecurity. cbSecurity will generate a new jwt secret each time the application expires and reloads. Which can also be nice to have.  You decide the approach!

Copy the output of the key and paste it into the `.env` setting called `JWT_SECRET`

```bash
JWT_SECRET=/TvWsL6k2Ap2/wbDroYmM9WT5JF/PndOdlzpJQEqUuI=
```

Now we need to reinit our server since we added a new secret.

```bash
// restart the server
server restart
```

## Securfity Visualizer

Go to http://127.0.0.1:42518/cbsecurity and you can see the security visualizer.  Super useful!

That's it!  Make sure your tests work: `testbox run`
