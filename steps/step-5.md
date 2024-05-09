# Step 5 - Registration

Let's focus now on the user registration requirement. This is the BDD story to complete:

```java
story( "I want to be able to register users in my system and assign them a JWT token upon registration" );
```

Let's start by modeling our user object, which our rest template has already pre-built for us: [`models/User.cfc`](../src/models/User.cfc).  When you open it let's go over what it includes and what we need to add.  We will also need to create the appropriate migrations for it.

## `User.cfc`

The delegations we defaulted by the rest template are:

* `Validatable@cbvalidation` - Tons of cool validation methods
* `Population@cbDelegates` - Ways to populate the object
* `Auth@cbSecurity` - Security methods
* `Authorizable@cbSecurity` - Authorization methods
* `JwtSubject@cbSecurity` - JWT methods

Where do we go to discover what these methods are???

* https://s3.amazonaws.com/apidocs.ortussolutions.com/coldbox-modules/cbvalidation/4.4.0/index.html
* https://s3.amazonaws.com/apidocs.ortussolutions.com/coldbox-modules/cbsecurity/3.5.0/index.html
* https://s3.amazonaws.com/apidocs.ortussolutions.com/coldbox/7.3.0/index.html

The properties we inherit from cbsecurity are:

* `id`
* `firstName`
* `lastName`
* `username`
* `password`
* `permissions`
* `roles`

The properties we need to add are:

* `createdDate:date`
* `modifiedDate:date`

We will also add an injection to QB so it can help us do queries and a much nicer way to do constraints.

```java
property name="qb" inject="model:QueryBuilder@qb";
```

In our constructor we will also add new features for:

* constraints
* memento

```groovy
function init(){
    super.init();

    // Update constraints
    this.constraints.username = {
        required : true,
        udf : ( value, target ) => {
            if( isNull( arguments.value ) ) return false;
            return qb.from( "users" ).where( "username", arguments.value ).count() == 0;
        }
    };

    // Change default includes to just *
    this.memento.defaultIncludes = [ "*" ];

    // Initialize dates
    variables.createdDate = now();
    variables.modifiedDate = now();

    return this;
}
```

Run your tests! We have broken a few things, but we will get them sorted out soon.


## Database Migrations

Just like you can version your source code, we can also version the database structure, and data by using database migrations.  The migrations project is divided into two modules that work together in unison.

- **CommandBox Migrations** (`commandbox-migrations`) which is the CLI module that will allow you to init, run, remove, etc migrations from your CLI using CommandBox: https://forgebox.io/view/commandbox-migrations
- **CFMigrations** (`cfmigrations`) which is the module that powers all the migrations system.  The CommandBox Migrations module actually uses this module as a dependency.  You can also use the migrations programmatically in your ColdBox applications as a module: https://forgebox.io/view/cfmigrations

Migrations are a way of providing version control for your application's database schema. Changes to the schema are kept in timestamped files that are ran in order `up` and `down`.  In the `up` function, you describe the changes to apply your migration. In the `down` function, you describe the changes to undo your migration.

```js
component {

    function up( schema, qb ) {
    	schema.create( "users", function( t ) {
            t.increments( "id" );
            t.string( "email" );
            t.string( "password" );
        } );
    }

    function down( schema, qb ) {
        schema.drop( "users" );
    }

}
```

Please note that migrations leverages also the `qb` module which allows you to do not only fluent queries, but also has an amazing `schema` builder.  The `qb` schema builder is incredibly powerful as it can abstract the creation, altering, modification of any construct in any database.  Keep this URL handy for documentation purposes: https://qb.ortusbooks.com/schema-builder/schema-builder


### Initalize Migrations

Run the following command to initialize your project with migrations:

```bash
migrations init
```

This will create a `.cfmigrations` in your root.  This file is used to describe where your migrations live and the connection details.  Please note that as of v4 of cfmigrations, you can use this file to maintain multiple managers.  Meaning you can create multiple migrations with different configurations.

Update the following properties in the `.cfmigrations` file:

```json
"schema": "${DB_DATABASE}",
```

Now let's make sure we can connect to our database and create the migrations table:

```bash
migrate install

Migration table installed!
```

If the table does not exist, this will create the table in your db called `cfmigrations`. If you refresh your db, you should see the table. If you run the command again, it will let you know it is already installed. Try it!


### Create the `users` migration

```sh
migrate create create_users_table
```

All migration resources are stored by default under `resources/database/migrations/**.cfc`.  Make sure these are in version control. They can save your life!  The migration file was created by the last command, and the file location was output by commandbox.  If you are using VS Code, you can just `Ctrl|cmd` + Click to open the file.

Let's now create the `users` table.  In the example below you can see a MySQL specific query execution and also a DB agnostic creation using the Schema Builder.  The Schema Builder is the best approach as it abstracts the database.

```java
component {

    function up( schema ) {
        schema.create( "users", function( table ) {
            table.increments( "id" )
            table.string( "firstName" )
            table.string( "lastName" )
            table.string( "username" ).unique()
            table.string( "password" )
            table.timestamps()
        } );
    }

    function down( schema ) {
        schema.drop( "users" )
    }

}
```

> QB Schema Builder Docs: https://qb.ortusbooks.com/schema-builder/schema-builder, your new best friend.

Now let's run it!

```sh
migrate up
```

Check your database, and you should see the database table. You can migrate `up` and `down` to test both functions. Go for it, tear it down: `migrate down`, and now back up: `migrate up`.

> If all else fails: `migrate fresh` is your best bet! (https://www.forgebox.io/view/commandbox-migrations)


## BDD Tests

Now that our model is complete and satisfies the **cbsecurity** requirements for authentication and jwt services let's focus on the actual registration. We will create our BDD spec first to write down our requirements.  We will then proceed to create the implementation.

Our template comes with a handler for authentication and an integration test as well:

* [`modules_app/api/modules_app/v1/handlers/Auth.cfc`](../src/modules_app/api/modules_app/v1/handlers/Auth.cfc)
* [`tests/specs/integration/AuthTests.cfc`](../src/tests/specs/integration/AuthTests.cfc)

Let's open our test and modify it a bit by making sure it inherits from our base class, remove some boilerplate and also update it for our new model.  Also, let's comment out the stories pre-generated for us so we can focus only on the registration story (Use the `x` prefix)

It should end up like this:

```java
component extends="tests.resources.BaseIntegrationSpec" {

	property name="jwtService" inject="provider:JwtService@cbsecurity";
	property name="cbauth"     inject="provider:authenticationService@cbauth";

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "RESTFul Authentication", function(){
			beforeEach( function( currentSpec ){
				// Setup as a new ColdBox request, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();

				// Make sure nothing is logged in to start our calls
				cbauth.logout();
				jwtService.getTokenStorage().clearAll();
			} );

			xstory( "I want to authenticate a user and receive a JWT token", function(){
				given( "a valid username and password", function(){
					then( "I will be authenticated and will receive the JWT token", function(){
						// Use a user in the seeded db
						var event = this.post(
							route  = "/api/v1/login",
							params = { username : "admin", password : "admin" }
						);
						var response = event.getPrivateValue( "Response" );
						expect( response.getError() ).toBeFalse( response.getMessages().toString() );
						expect( response.getData() ).toBeString();

						// debug( response.getData() );

						var decoded = jwtService.decode( response.getData() );
						expect( decoded.sub ).toBe( 1 );
						expect( decoded.exp ).toBeGTE( dateAdd( "h", 1, decoded.iat ) );
					} );
				} );
				given( "invalid username and password", function(){
					then( "I will receive a 401 exception ", function(){
						var event = this.post(
							route  = "/api/v1/login",
							params = { username : "invalid", password : "invalid" }
						);
						var response = event.getPrivateValue( "Response" );
						expect( response.getError() ).toBeTrue();
						expect( response.getStatusCode() ).toBe( 401 );
					} );
				} );
			} );

			story( "I want to register into the system", function(){
				given( "valid registration details", function(){
					then( "I should register, log in and get a token", function(){
						// Use a user in the seeded db
						var event = this.post(
							route  = "/api/v1/register",
							params = {
								firstName : "luis",
								lastName  : "majano",
								username  : "lmajano@coldbox.org",
								password  : "lmajano"
							}
						);
						var response = event.getPrivateValue( "Response" );
						expect( response.getError() ).toBeFalse( response.getMessages().toString() );
						expect( response.getData() ).toHaveKey( "token,user" );

						// debug( response.getData() );

						var decoded = jwtService.decode( response.getData().token );
						expect( decoded.sub ).toBe( response.getData().user.id );
						expect( decoded.exp ).toBeGTE( dateAdd( "h", 1, decoded.iat ) );
					} );
				} );
				given( "invalid registration details", function(){
					then( "I should get an error message", function(){
						var event    = this.post( route = "/api/v1/register", params = {} );
						var response = event.getPrivateValue( "Response" );
						// debug( response.getMemento() );
						expect( response.getError() ).toBeTrue();
						expect( response.getStatusCode() ).toBe( 400 );
					} );
				} );
			} );

			xstory( "I want to be able to logout from the system using my JWT token", function(){
				given( "a valid incoming jwt token", function(){
					then( "my token should become invalidated and I will be logged out", function(){
						// Log in first to get a valid token to logout with
						var token   = jwtService.attempt( "admin", "admin" );
						var payload = jwtService.decode( token );
						expect( cbauth.isLoggedIn() ).toBeTrue();

						// Now Logout
						var event = this.post( route = "/api/v1/logout", params = { "x-auth-token" : token } );

						var response = event.getPrivateValue( "Response" );
						expect( response.getError() ).toBeFalse( response.getMessages().toString() );
						expect( response.getStatusCode() ).toBe( 200 );
						expect( cbauth.isLoggedIn() ).toBeFalse();
					} );
				} );
				given( "an invalid incoming jwt token", function(){
					then( "I should see an error message", function(){
						// Now Logout
						var event = this.post( route = "/api/v1/logout", params = { "x-auth-token" : "123" } );

						var response = event.getPrivateValue( "Response" );
						expect( response.getError() ).toBeTrue( response.getMessages().toString() );
						// debug( response.getStatusCode( 500 ) );
					} );
				} );
			} );
		} );
	}

}
```

It will be green, but remember we are mocking everything still.


## Routing

Open the `v1` module's router: [`modules_app/api/modules_app/v1/config/Router.cfc`](../src/modules_app/api/modules_app/v1/config/Router.cfc) and verify all the pre-generated routes.  We don't have to do anything now, but verify all of our routing in the route visualizer module: http://127.0.0.1:42518/route-visualizer

## Event Handler

Now that we have our route, let's fill review our event handler for registration only.  Open the [`Auth.cfc`](../src/modules_app/api/modules_app/v1/handlers/Auth.cfc) in our `v1` module and review the `register()` action.  Once we see this code, two new scenarios should pop up in your head:

```js
given( "invalid registration details", function() {
	then( "I should get an error message", function() {

    });
} );
given( "valid registration data but with a non-unique username", function(){
    then( "a validation message should be sent to the user with an error message", function(){

    });
} );
```

You will have to fill these out on your own! Let's do it!

## User Services

We now need to implement our story, so let's forget about mocking and let's do it! Open the [UserService.cfc](../src/models/UserService.cfc) and it's test [UserServiceTest.cfc](../src/tests/specs/unit/UserServiceTest.cfc). We will only test creation of the service, since the rest will be via the BDD stories in our integration tests.  So cleanup the tests and leave it like so:

```java
component extends="coldbox.system.testing.BaseTestCase" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
	}

	function afterAll(){
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "UserService", function(){
			beforeEach( function( currentSpec ){
				setup();
				model = getInstance( "UserService" );
			} );

			it( "can be created", function(){
				expect( model ).toBeComponent();
			} );

		} );
	}

}
```

Now we can update the service `create` method to support our registration story.  We will also add some injections to the service to help us with the registration process.  Also remember to remove the mocked property. We won't be using that now.

```java
/**
 * --------------------------------------------------------------------------
 * DI
 * --------------------------------------------------------------------------
 */

property name="populator" inject="wirebox:populator";
property name="bcrypt"      inject="@BCrypt";
property name="qb"          inject="provider:QueryBuilder@qb";

...

function init(){
    return this;
}

User function create( required user ){
    var qResults = qb.from( "users" )
        .insert( values = {
            "firstName"   : arguments.user.getFirstName(),
            "lastName"    : arguments.user.getLastName(),
            "username"    : arguments.user.getUsername(),
            "password" 	:  variables.bcrypt.hashPassword( arguments.user.getPassword() )
        } );

    // populate the id
    arguments.user.setId( qResults.result.generatedKey );

    return arguments.user;
}

```


Now let's verify our tests and adjust as necessary, but we should have a working registration now and jwt token creations.  Also, check out your database, a new table `cbjwt` has been created for you!

Question, why doesn't the table have any data on it?

> Go into the base integration test and remove the `aroundEach` annotation from the `wrapInTransaction()` method, run the tests, and check out the database now. Run again, the data persists.  So be careful, decide and move on. Clear the db data if you like.
