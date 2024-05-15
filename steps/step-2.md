# Step 2 - Scaffold Your Application

In this step, we will scaffold our application and configure our test harness. Use the provided `src` folder, to create your application. Make sure you are running all commands within that `src` folder.

## Starting the Database

We will be using docker for this section.  Just run this command from the root of this repo.  A new `build/db` will be created that will represent your database.

```bash
docker-compose up
```

> If you don't have docker, you better have a MySQL 8 install locally.  You can then use the `workbench/db/cms.sql` to populate your database.

Now open up your favorite SQL tool and make sure you can connect with the following credentials:

```bash
server: 127.0.0.1
port: 3307
database: cms
user: cms
password: coldbox
```

Your database should be online now, test it with your favorite tool.

## Global Dependencies

Before we start let's make sure we have our global CommandBox dependencies that we will use for environment control, cfconfig for CFML portability (cfconfig - https://cfconfig.ortusbooks.com/):

```bash
install commandbox-dotenv,commandbox-cfconfig,commandbox-cfformat,coldbox-cli
```

## Scaffold the application

```bash
cd src
coldbox create app name=cms skeleton=rest-hmvc
```

We will now begin creating our application using CommandBox.  This will scaffold out a REST application using our `rest-hmvc` template.  It will create a modular approach to our API based on ColdBox 7.  The following dependencies will be installed for you:

* `coldbox` - Super HMVC Framework
* `testbox` - BDD testing library (`development` dependency)
* `modules/cbsecurity` - For securing your API
* `modules/cbvalidation` - For validating your API
* `modules/mementifier` - For marshalling objects to data
* `modules/relax` - Module for documenting, exploring and testing our API (`development` dependency)
  * `modules/cbSwagger` - Open API support for documenting our API
* `modules/route-visualizer` - For visualizing our routes

```bash
Dependency Hierarchy for cms (1.0.0)
├── route-visualizer (2.0.0+6)
├── coldbox (7.2.1+13)
├── relax (4.1.1+193)
├── testbox (5.3.1+6)
├── cbsecurity (3.4.2+4)
├── mementifier (3.4.0+2)
└── cbvalidation (4.4.0+26)
```

Let's go over what is in this template.

> Also run a `coldbox create app ?` to see all the different ways to generate an app.  You can also use `coldbox create app-wizard ?` and follow our lovely wizard.

## Updating our `.env` file

Update the environment file with the following information:

```bash
# ColdBox Environment
APPNAME=ColdBox
ENVIRONMENT=development

# Database Information
DB_CONNECTIONSTRING=jdbc:mysql://localhost:3307/cms?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC&useLegacyDatetimeCode=true&allowPublicKeyRetrieval=true
DB_CLASS=com.mysql.cj.jdbc.Driver
DB_BUNDLENAME=com.mysql.cj
DB_BUNDLEVERSION=8.0.33
DB_DRIVER=MySQL
DB_HOST=localhost
DB_PORT=3307
DB_DATABASE=cms
DB_USER=cms
DB_PASSWORD=coldbox

# JWT Information
JWT_SECRET=
```

This will allow for CommandBox and the servers we run have access to these environment settings.  **MAKE SURE YOU USE `LOCALHOST` INSTEAD OF THE IP FOR DOCKER**

> We will fill out the JWT Secret later on.

## Automatic Formatting Goodness

We have included automatic code formatting for you.  This will help you keep your code clean and consistent.  We have added a `.cfformat.json` file that will be used by the `commandbox-cfformat` module.  This will format your code automatically every time you save your file.  Just run the watcher via the CLI:

```bash
run-script format:watch
```

## Start up the local server

We use a standard port, so that in the steps and in the training we can all use the same port.  It makes it easier for the class. However, please note that you can omit this and use whatever port is available in your machine.  If the `42518` port is already in use, please make sure you use another port.

```sh
server start port=42518
```

Boom!  Our REST API is now online and ready to be consumed.  Let's test it out.

* Open `http://localhost:42518/` in your browser. You should see the default ColdBox app template
* Open `/tests` in your browser. You should see the TestBox test browser.  This is useful to find a specific test or group of tests to run _before_ running them.
* Open `/tests/runner.cfm` in your browser. You should see the TestBox test runner for our project

This is running all of our tests by default. We can create our own test runners as needed.  All your tests should be passing at this point. 😉

> Tip: `server log --follow` to see the console logs of your server, try it out. All logging messages will also appear here as well.  Great to have in a separate window.

## Testing via CommandBox

```sh
# package set testbox.runner="http://localhost:42518/tests/runner.cfm"
testbox run
```

You can also configure the way TestBox runs the tests via the `box.json`.  Open it and look for the `testbox` section. You can also find much more detailed information in the docs here:

* https://commandbox.ortusbooks.com/package-management/box.json/testbox
* https://commandbox.ortusbooks.com/testbox-integration/test-runner
* https://commandbox.ortusbooks.com/testbox-integration/test-watcher

Now run the help command to check out all the different ways we can test via the CLI: `testbox run ?`

## CommandBox Test Watchers

CommandBox supports Test Watchers. This allows you to automatically run your tests as you make changes to tests or CFCs in your application. You can start CommandBox Test watchers with the following command:

```sh
testbox watch
```

You can also control what files to watch via the command or via the `testbox` structure in your `box.json` file.

```sh
testbox watch **.cfc
```

`ctl-c` will escape and stop the watching.  Start it up again and now go open the `models/UserService.cfc` that was generated: [Open](../src/models/UserService.cfc:62).  Change the `append()` and introduce a bug by renaming it to `apppend()`. Save the file and check out the watcher!  Fix the bug and see the watcher run the tests again.
