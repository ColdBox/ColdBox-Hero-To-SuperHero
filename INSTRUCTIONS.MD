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
DB_CONNECTIONSTRING=jdbc:mysql://127.0.0.1:3307/cms?useSSL=false&useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC&useLegacyDatetimeCode=true
DB_CLASS=com.mysql.jdbc.Driver
DB_DRIVER=MySQL
DB_HOST=127.0.0.1
DB_PORT=3307
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

```json
{
	"requestTimeoutEnabled":true,
    "whitespaceManagement":"white-space-pref",
	"requestTimeout":"0,0,5,0",
	"cacheDefaultObject":"coldbox",
    "caches":{
        "coldbox":{
            "storage":"true",
            "type":"RAM",
            "custom":{
                "timeToIdleSeconds":"1800",
                "timeToLiveSeconds":"3600"
            },
            "class":"lucee.runtime.cache.ram.RamCache",
            "readOnly":"false"
        }
    },
	"datasources" : {
		 "${DB_DATABASE}":{
			 "host":"${DB_HOST}",
			 "dbdriver":"${DB_DRIVER}",
			 "database":"${DB_DATABASE}",
			 "dsn":"jdbc:mysql://{host}:{port}/{database}",
			 "custom":"useUnicode=true&characterEncoding=UTF-8&useLegacyDatetimeCode=true&autoReconnect=true",
			 "port":"${DB_PORT}",
			 "class":"${DB_CLASS}",
			 "username":"${DB_USER}",
			 "password":"${DB_PASSWORD}",
			 "connectionLimit":"100",
			 "connectionTimeout":"1"
		 }
	}
}
```


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

 * `qb` - Fluent query builder for fancy queries (https://forgebox.io/view/qb)
 * `cbvalidation` - To provide server side validations (https://forgebox.io/view/cbValidation)
 * `bcrypt` - To enable encrypting of passwords (https://www.forgebox.io/view/BCrypt)
 * `cbsecurity` - To secure our API and provide us with JWT Tokens (https://www.forgebox.io/view/cbsecurity)
 * `mementifier` - To convert our objects to native data structures for JSON exporting (arrays/structs) (https://www.forgebox.io/view/mementifier)
 * `route-visualizer` : Visualizer your routes (https://www.forgebox.io/view/route-visualizer)
  

```bash
install route-visualizer --saveDev
install cbvalidation,qb,bcrypt,mementifier,cbsecurity
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
story( "I want to be able to register users in my system and assign them a JWT token upon registration" );
```

Let's start by modeling our user object:

### `User.cfc`

Here are the properties we want to model

* `id`
* `name`
* `email`
* `username`
* `password`
* `createdDate:date`
* `modifiedDate:date`

We will create the model object and a basic compile unit test:

```bash
coldbox create model name="User"  properties="id,name,email,username,password,createdDate:date,modifiedDate:date"
```

Let's open the file and add some initialization procedures and a utility method to know if the User object has been populated from the database or not: `isLoaded()`.  We will also add instructions for the `mementifier` module to know how to convert the object to JSON, and our validation constraints.

```js
/**
* I am a new Model Object
*/
component accessors="true"{
    
    // DI
    property name="qb" inject="provider:QueryBuilder@qb";

	// Properties
	property name="id"           type="string";
	property name="name"         type="string";
	property name="email"        type="string";
	property name="username"     type="string";
	property name="password"     type="string";
	property name="createdDate"  type="date";
    property name="modifiedDate" type="date";
    
    this.constraints = {
        name        : { required : true },
        email       : { required : true, type : "email" },
        username    : { required : true, udf : ( value, target ) => {
            return qb.from( "users" ).where( "username", arguments.value ).count() == 0;
        }},
        password    : { required : true }
    };

    this.memento = {
		defaultIncludes = [ "*" ],
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

Now open the unit test: `/tests/specs/unit/UserTest.cfc` and update it to this:

```java
describe( "A User", function(){
			
    it( "can be created", function(){
        expect( model ).toBeComponent();
    });

});
```

Run your tests!

### Authentication and JWTSubject

Since we will be using cbsecurity's authentication service (**cbauth**) and it's jwt services, let's make sure our User object adhers to those requirements by implementing the methods it asks us to do. We won't test them, since those will be tested by the integration portions.

`IAuthUser` - https://coldbox-security.ortusbooks.com/usage/authentication-services#user-interface

We will skip adding the `getId()` function since that is added already by the accessor.  We don't have any permissions yet in the system, so we will always return true, and for `isLoggedIn()` we will delegate to cbauth (`authenticationService@cbauth`).

```js
interface{

    /**
     * Return the unique identifier for the user
     */
    function getId();

    /**
     * Verify if the user has one or more of the passed in permissions
     *
     * @permission One or a list of permissions to check for access
     *
     */
    boolean function hasPermission( required permission );

    /**
     * Shortcut to verify it the user is logged in or not.
     */
    boolean function isLoggedIn();

}
```

`IJwtSubject` - https://coldbox-security.ortusbooks.com/jwt/jwt-services#jwt-subject-interface

For now we won't have any custom claims or custom security scopes.  Maybe later on in our training we will add them.

```js
interface{

    /**
     * A struct of custom claims to add to the JWT token
     */
    struct function getJwtCustomClaims();

    /**
     * This function returns an array of all the scopes that should be attached to the JWT token that will be used for authorization.
     */
    array function getJwtScopes();

}
```

So our `User.cfc` will end up like this:

```js
/**
* I am a new Model Object
*/
component accessors="true"{

	// DI
    property name="auth" inject="authenticationService@cbauth";
    property name="qb" inject="provider:QueryBuilder@qb";

	// Properties
	property name="id"           type="string";
	property name="name"         type="string";
	property name="email"        type="string";
	property name="username"     type="string";
	property name="password"     type="string";
	property name="createdDate"  type="date";
	property name="modifiedDate" type="date";

    this.constraints = {
        name        : { required : true },
        email       : { required : true, type : "email" },
        username    : { required : true, udf : ( value, target ) => {
            return qb.from( "users" ).where( "username", arguments.value ).count() == 0;
        }},
        password    : { required : true }
    };

    this.memento = {
		defaultIncludes = [ "*" ],
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

	/**
     * A struct of custom claims to add to the JWT token
     */
    struct function getJwtCustomClaims(){
		return {};
	}

    /**
     * This function returns an array of all the scopes that should be attached to the JWT token that will be used for authorization.
     */
	array function getJwtScopes(){
		return [];
	}

    /**
     * Verify if the user has one or more of the passed in permissions
     *
     * @permission One or a list of permissions to check for access
     *
     */
    boolean function hasPermission( required permission ){
		return true;
	}

    /**
     * Shortcut to verify it the user is logged in or not.
     */
    boolean function isLoggedIn(){
		return auth.isLoggedIn();
	}

}
```

Run your tests again and see if it compiles.

### BDD Integration

Now that our model is complete and satisfies the cbsecurity requirements for authentication and jwt services let's focus on the actual registration. We will create our BDD spec first to write down our requirements.  We will then rprceed to create the implementation.

```bash
coldbox create handler name="registration" actions="create" directory=modules_app/api/modules_app/v1/handlers
```

The BDD test will be created here: `/tests/specs/integration/registrationTest.cfc` and we will start here:

```js
component extends="tests.resources.BaseIntegrationSpec"{

	property name="qb" inject="provider:QueryBuilder@qb";

	/*********************************** BDD SUITES ***********************************/

	function run(){

		story( "I want to be able to register users in my system and assign them a JWT token upon registration", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
			});

			given( "valid registration data and the username is available", function(){
				then( "I will be able to register my new user and get an access token", function(){
					// Test user doesn't exist
					expect(
						qb.from( "users" )
							.where( "username", "testadmin" )
							.count()
					).toBe( 0 );

					var event = post( "/api/v1/registration", {
						"name"					= "Your Name",
						"email"                	= "testadmin@ortussolutions.com",
						"username"             	= "testadmin",
						"password"             	= "testadmin"
					} );
					var response = event.getPrivateValue( "response" );

					expect( response.getError() ).toBeFalse();
					expect( response.getData().token ).notToBeEmpty();
					expect( response.getData().user.id ).toBeNumeric();
					expect( response.getData().user.name ).toBe( "Your Name" );

					// data = { user:struct, token:jwt token }

				});
			});

		});

	}

}
```

Run it, of course it will fail!

### Routing

Ok, let's start our implementation by adding our registration routes.  We will be basing all our routes on ColdBox Resources (https://coldbox.ortusbooks.com/the-basics/routing/routing-dsl/resourceful-routes) as much as possible in order to make our handlers standardized and light-weight.

Open the `v1` module's router: `modules_app/api/modules_app/v1/config/Router.cfc` and add our resources:

```js
component{

    function configure(){

		route( "/", "echo.index" );

		resources( resource="registration", only="create" );

        route( "/:handler/:action" ).end();
    }

}
```

This will add all the necessary routing for the `registration` resource under the `v1` module.  Issue a `coldbox reinit` and check out the Route Visualizer: http://127.0.0.1:42518/route-visualizer

### Event Handler

Now that we have our route, let's fill out our event handler for registration.  Open the `registration.cfc` in our `v1` module and let's code it out.  We will need to populate a new user object from incoming `rc` data, validate it, create it and then tell the cbsecurity's jwt services to create a token for the user.  Also remember that our handler's MUST Inherit from our `BaseHandler` from our `api` module.

```js
/**
 * My RESTFul Event Handler which inherits from the module `api`
 */
component extends="api.handlers.BaseHandler"{

	// DI
	property name="userService"	inject="UserService";

	/**
	 * Register a new user in our system
	 */
	function create( event, rc, prc ){
		// populate, validate and create
		prc.oUser = userService.create(
			validateOrFail( populateModel( "User" ) )
		);

		// Respond back with user rep and token
		prc.response.setData( {
			"user" 	: prc.oUser.getMemento(),
			"token"	: jwtAuth().fromUser( prc.oUser )
		} );
	}

}
```

Once we write up this code, two new scenarios should pop up in your head:

```js
given( "invalid registration data", function(){
    then( "a validation message should be sent to the user with a 400 error code", function(){

    });
} );
given( "valid registration data but with a non-unique username", function(){
    then( "a validation message should be sent to the user with a 400 error code", function(){

    });
} );
```

You will have to fill these out on your own!  

### User Services

Since we must use a `UserService` in our handler, then I guess we need to build it.  How? Well, we know we need to add a `create()` method:

Let's generate the model alongside its unit test.

```bash
coldbox create model name="UserService" persistence="singleton" methods="create"
```

Open the unit test `tests/specs/unit/UserServiceTest.cfc` and just do a compile time test, the rest will be covered by the integration tests.

```js
describe( "UserService", function(){
    it( "can be created", function(){
        expect( model ).toBeComponent();
    });
});
```

Now let's do the code implementations for the service:

```js
/**
* User Services
*/
component singleton accessors="true"{

	// Properties
	property name="bcrypt"      inject="@BCrypt";
	property name="qb"          inject="provider:QueryBuilder@qb";

	/**
	 * Constructor
	 */
	UserService function init(){
		return this;
	}

	User function new() provider="User";

	/**
	* create
	*/
	function create( required user ){
		var qResults = qb.from( "users" )
			.insert( values = {
				"name" 		= arguments.user.getName(),
				"email" 	= arguments.user.getEmail(),
				"username" 	= arguments.user.getUsername(),
				"password" 	= bcrypt.hashPassword( arguments.user.getPassword() )
			} );

		// populate the id
		arguments.user.setId( qResults.generatedKey );

		return arguments.user;
	}

}
```

Now let's verify our tests and adjust as necessary, but we should have a working registration now.