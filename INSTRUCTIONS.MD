# Steps to go from ColdBox Hero to SUPERHERO

(All commands assume we are in the `box` shell unless stated otherwise.)

## Create App Folder

Create a new application folder where we will build our app on, call it `hcms` and place the given docker compose file in the root and the workbench folder as well.

```
hcms
 + docker-compose.yaml
 + workbench
```

## Starting the Database

```
docker-compose up
```

Now open up your favorite SQL tool and make sure you can connect with the following credentials:

```
server: 127.0.0.1
port: 3307
database: cms
user: cms
password: coldbox
```

Your database should be online and populated with mock data.

> Tip: You can find the database export file here `/workbench/db/cms.sql`. You will also find the migrations we used and the seeder we used for populating the database.

## Global Dependencies

Before we start let's make sure we have our global CommandBox dependencies that we will use for environment control, cfconfig for CFML portability (cfconfig - https://cfconfig.ortusbooks.com/):

```bash
install commandbox-dotenv,commandbox-cfconfig
```

## Creating our REST HMVC App

We will now begin creating our application using CommandBox.  This will scaffold out a REST application using our `rest-hmvc` template.  It will create a modular approach to our API so we will have versions and a pre-configured `Response` object and a `BaseHandler` for uniformity and data manipulation.

The following dependencies will be installed for you:

* `coldbox` - Super HMVC Framework
* `testbox` - BDD testing library (`development` dependency)
* `modules/cbSwagger` - Open API support for documenting our API
* `modules/relax` - Module for documenting, exploring and testing our API (`development` dependency)

```bash
coldbox create app name=cms skeleton=rest-hmvc
```

## Updating our `.env` file

Update the environment file with the following information:

```bash
# ColdBox Environment
APPNAME=ColdBox
ENVIRONMENT=development

# Database Information
DB_CONNECTIONSTRING=jdbc:mysql://127.0.0.1:3306/cms?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC&useLegacyDatetimeCode=true
DB_CLASS=com.mysql.jdbc.Driver
DB_DRIVER=MySQL
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=cms
DB_USER=cms
DB_PASSWORD=coldbox

# JWT Information
JWT_SECRET=

# S3 Information
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_REGION=us-east-1
S3_DOMAIN=amazonaws.com
```

This will allow for CommandBox and the servers we run have access to these environment settings.

> We will fill out the JWT Secret later on.

## CFConfig

Let's review our `.cfconfig.json` file.

## Start it up!

Let's start our server up but let's configure it to use the `42518` port so we can all share URL's

```bash
server start port=42518
```

Boom!  Our REST API is now online

> Tip: `server log --follow` to see the console logs of your server, try it out. All logging messages will also appear here as well.  Great to have in a separate window.

## BDD Tests

Let's also discover the automated tests that were created for us.  Navigate to the following URL:
http://localhost:42518/tests/runner.cfm and you will see the test results.  Check out the specs in `tests/specs` as well.

Now let's try it via CommandBox CLI

```sh
testbox run "http://localhost:42518/tests/runner.cfm"
```

Now let's tell CommandBox about our runner.

```sh
package set testbox.runner="http://localhost:42518/tests/runner.cfm"
testbox run
```

Cool.  Now we can test our stuff without leaving the editor.  Let's make this even more cooler.  

```
testbox watch
```

This will start a watcher so you can do your code changes and tests will be executed automatically for you.  Go break a test and check it out.

## More Modules

We will install several modules to assist us with the development of our API

  * `route-visualizer` : Visualizer your routes (https://www.forgebox.io/view/route-visualizer)
  * `bcrypt` - To enable encrypting of passwords (https://www.forgebox.io/view/BCrypt)
  * `cbsecurity` - To secure our API and provide us with JWT Tokens (https://www.forgebox.io/view/cbsecurity)
  * `mementifier` - To convert our objects to native data structures for JSON exporting (arrays/structs) (https://www.forgebox.io/view/mementifier)

```bash
install route-visualizer,bcrypt,mementifier,cbsecurity
coldbox reinit
```



