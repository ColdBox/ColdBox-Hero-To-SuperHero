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
install route-visualizer --saveDev
install bcrypt,mementifier,cbsecurity
coldbox reinit
```

## Adding our Datasource Globally

Open `Application.cfc`  so we can add the global datasource we registered with the CFML Engine via  `.cfconfig.json`

```js
// App datasource
this.datasource = "cms";
```

Let's do the same with the tets application: `/tests/Application.cfc`

```js
// App datasource
this.datasource = "cms";
```

Try running the app again. If it runs, it works.  Or just issue a `testbox run`


## Our Base Integration Testing Class

Let's create a base testing class all our integration tests will inherit from.  Place it under `tests/resources/BaseIntegrationSpec.cfc`


```js
component extends="coldbox.system.testing.BaseTestCase" appMapping="/root"{

    // Load on first test
    this.loadColdBox    = true;
    // Never unload until the request dies
    this.unloadColdBox  = false;

    /**
     * Run Before all tests
     */
    function beforeAll() {
        super.beforeAll();
        // Wire up the test object with dependencies
        application.wirebox.autowire( this );
    }

    /**
     * This function is tagged as an around each handler.  All the integration tests we build
     * will be automatically rolled backed. No database corruption
     * 
     * @aroundEach
     */
    function wrapInTransaction( spec ) {
        transaction action="begin" {
            try {
                arguments.spec.body();
            } catch ( any e ){
                rethrow;
            } finally {
                transaction action="rollback";
            }
        }
    }

}
```

Update the `tests/specs/integration/EchoTests.cfc` to inherit from this spec and verify it works. It should look like this:

```js
/*******************************************************************************
*	Integration Test as BDD (CF10+ or Railo 4.1 Plus)
*
*	Extends the integration class: coldbox.system.testing.BaseTestCase
*
*	so you can test your ColdBox application headlessly. The 'appMapping' points by default to
*	the '/root' mapping created in the test folder Application.cfc.  Please note that this
*	Application.cfc must mimic the real one in your root, including ORM settings if needed.
*
*	The 'execute()' method is used to execute a ColdBox event, with the following arguments
*	* event : the name of the event
*	* private : if the event is private or not
*	* prePostExempt : if the event needs to be exempt of pre post interceptors
*	* eventArguments : The struct of args to pass to the event
*	* renderResults : Render back the results of the event
*******************************************************************************/
component extends="tests.resources.BaseIntegrationSpec"{

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "My RESTFUl Service", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
			});

			it( "can handle invalid HTTP Calls", function(){
				var event = execute( event="v1:echo.onInvalidHTTPMethod", renderResults = true );
				var response = event.getPrivateValue( "response" );
				expect(	response.getError() ).toBeTrue();
				expect(	response.getStatusCode() ).toBe( 405 );
			});

			it( "can handle global exceptions", function(){
				var event = execute(
					event 			= "v1:echo.onError",
					renderResults 	= true,
					eventArguments	= { exception={ message="unit test", detail="unit test", stacktrace="" } }
				);

				var response = event.getPrivateValue( "response" );
				expect(	response.getError() ).toBeTrue();
				expect(	response.getStatusCode() ).toBe( 500 );
			});

			it( "can handle an echo", function(){
				var event 		= this.request( "/api/v1/echo/index" );
				var response 	= event.getPrivateValue( "response" );
				expect(	response.getError() ).toBeFalse();
				expect(	response.getData() ).toBe( "Welcome to my ColdBox RESTFul Service" );
			});

			it( "can handle missing actions", function(){
				var event 		= this.request( "/api/v1/echo/bogus" );
				var response 	= event.getPrivateValue( "response" );
				expect(	response.getError() ).tobeTrue();
				expect(	response.getStatusCode() ).toBe( 405 );
			});


		});

	}

}
```

## Security

We will start by configuring `cbsecurity` so we can secure our app and be able to provide Json Web Tokens (JWT) for securing our app.  Once the configuration is done, we will move on to start the user registration process.

- Go over cbSecurity
- Go over cbAuth
- Go over JWT

Open the `config/ColdBox.cfc` and locate the `moduleSettings`, we will be adding the following configuration for cbauth, cbsecurity and jwt. Please go over each configured setting below:

```js
moduleSettings = {

    cbauth = {
        // Which class will provide user information for authentication
        userServiceClass : "UserService"
    },

    cbsecurity = {
        // The global invalid authentication event or URI or URL to go if an invalid authentication occurs
        "invalidAuthenticationEvent"	: "v1:Main.onAuthenticationFailure",
        // Default Auhtentication Action: override or redirect when a user has not logged in
        "defaultAuthenticationAction"	: "override",
        // The global invalid authorization event or URI or URL to go if an invalid authorization occurs
        "invalidAuthorizationEvent"		: "v1:Main.onAuthorizationFailure",
        // Default Authorization Action: override or redirect when a user does not have enough permissions to access something
        "defaultAuthorizationAction"	: "override",
        // You can define your security rules here or externally via a source
        "rules"							: [
            // We will add them later
        ],
        // The validator is an object that will validate rules and annotations and provide feedback on either authentication or authorization issues.
        "validator"						: "JWTService@cbsecurity",
        // WireBox ID of the user service to use
        "userService"             		: "UserService",
        // Activate security rule visualizer, defaults to false by default
        "enableSecurityVisualizer"		: true,
        // JWT Settings
        "jwt"                     		: {
            // The jwt secret encoding key to use
            "secretKey"               : getSystemSetting( "JWT_SECRET", "" ),
            // by default it uses the authorization bearer header, but you can also pass a custom one as well or as an rc variable.
            "customAuthHeader"        : "x-auth-token",
            // The expiration in minutes for the jwt tokens
            "expiration"              : 60,
            // encryption algorithm to use, valid algorithms are: HS256, HS384, and HS512
            "algorithm"               : "HS512",
            // Which claims neds to be present on the jwt token or `TokenInvalidException` upon verification and decoding
            "requiredClaims"          : [] ,
            // The token storage settings
            "tokenStorage"            : {
                // enable or not, default is true
                "enabled"       : true,
                // A cache key prefix to use when storing the tokens
                "keyPrefix"     : "cbjwt_",
                // The driver to use: db, cachebox or a WireBox ID
                "driver"        : "db",
                // Driver specific properties
                "properties"    : {
                    "table" : "cbjwt"
                }
            }
        }
    }
}
```

Let's add the JWT Secret now, let's begin by generating a secret key. Go to CommandBox and let's generate one:

```bash
#generateSecretKey blowfish 256

>/TvWsL6k2Ap2/wbDroYmM9WT5JF/PndOdlzpJQEqUuI=
```

Copy the output of the key and paste it into the `.env` setting called `JWT_SECRET`

```bash
JWT_SECRET=/TvWsL6k2Ap2/wbDroYmM9WT5JF/PndOdlzpJQEqUuI=
```

Now we need to reinit our server since we added a new secret. Also, CommandBox CLI doesn't know about it, since you just added it, so let's reload the shell as well.  Go to CommandBox:

```
// Reload the shell
reload

// restar the server
restart
```

That's it!  Make sure your tests work: `testbox run`

## Registration

Let's focus now on the user registration requirement. This is the BDD story to complete:

```java
story( "I want to be able to register users in my system and assign them a JWT login token" );
```

Let's start by modeling our user object:

### User.cfc

Here are the properties we want to model

* `id`
* `name`
* `email`
* `username`
* `password`
* `createdDate:date`
* `modifiedDate:date`

We will create the model object, a basic compile unit test:

```bash
coldbox create model name="User"  properties="id,name,email,username,password,createdDate:date,modifiedDate:date"
```

Ahora, abramos el archivo y agreguemos inicializacion para las fechas, un metodo de utilidad para saber si el modelo es nuevo o viene de la base de datos `isLoaded()`, e instrucciones para el `mementifier` para saber como convertir este modelo a una represenacion nativa para Json.

```java
/**
* I am a new Model Object
*/
component accessors="true"{
	
	// Properties
	property name="id"           type="string";
	property name="name"         type="string";
	property name="email"        type="string";
	property name="username"     type="string";
	property name="password"     type="string";
	property name="createdDate"  type="date";
	property name="modifiedDate" type="date";
	
    this.memento = {
		defaultIncludes = [ "id", "name", "email", "username", "createdDate", "modifiedDate" ],
		neverInclude = [ "password" ]
	};

	/**
	 * Constructor
	 */
	User function init(){

		variables.createdDate = now();
		variables.modifiedDate = now();
		
		return this;
	}

	boolean function isLoaded(){
		return ( !isNull( variables.id ) && len( variables.id ) );
	}

}
```

Ahora abre la prueba: `/tests/specs/unit/UserTest.cfc`:

```java
describe( "Usuario", function(){
			
    it( "puede ser creado", function(){
        expect( model ).toBeComponent();
    });

});
```

Corre tus tests!