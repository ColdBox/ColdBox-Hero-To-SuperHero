# Step 7 - Authentication

Now that we have registration complete, let's focus on authentication for our API.  Here are two stories to start with which can be found already in our auth spec.

```java
story( "I want to be able to authenticate with a username/password and receive a JWT token", function(){

} );

story( "I want to be able to logout from the system using my JWT token", function(){

} );
```

## BDD

I want to start with the happy path of the login and add the following acceptance criteria:

- The request must give a `200` status code
- The response jwt subject id must be the same as the `user` id in the data packet

The last criteria is very important as it will allow us to test the JWT token generation and validation.  However, the pre-generated code does NOT return the `user` in the response, so we need to update the `login()` method in the `Auth` handler to return the user in the response.

We will end up with the following tests:

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

			story( "I want to authenticate a user and receive a JWT token", function(){
				given( "a valid username and password", function(){
					then( "I will be authenticated and will receive the JWT token", function(){
						// Use a user in the seeded db
						var event = this.post(
							route  = "/api/v1/login",
							params = {
								username : "admin",
								password : "admin"
							}
						);
						var response = event.getPrivateValue( "Response" );

						expect( response ).toHaveStatus( 200 );
						expect( response.getError() ).toBeFalse( response.getMessages().toString() );
						expect( response.getData() ).toBeString();

						// debug( response.getData() );

						var decoded = jwtService.decode( response.getData() );
						expect( decoded.sub ).toBe( 1 );
						expect( decoded.exp ).toBeGTE( dateAdd( "h", 1, decoded.iat ) );
						expect( decoded.sub ).toBe( response.getData().user.id );
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

						debug( response.getData() );

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

				xgiven( "valid registration data but with a non-unique username", function() {
					then( "a validation message should be sent to the user with an error message", function() {
					} );
				} );
			} );

			story( "I want to be able to logout from the system using my JWT token", function(){
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

If you run them, they will fail. Good!  Time to code!

## Routing

Open the `v1` module's router: [`modules_app/api/modules_app/v1/config/Router.cfc`](../src/modules_app/api/modules_app/v1/config/Router.cfc) and verify all the pre-generated routes.  As before we don't have to do anything now, but verify all of our routing in the route visualizer module: http://127.0.0.1:42518/route-visualizer

## Event Handler

Open the [`Auth.cfc`](../src/modules_app/api/modules_app/v1/handlers/Auth.cfc) in our `v1` module and review the `login() and logout()` actions.  The one we will modify is the `login()` as we need to return the authenticated user back in the data packet.  To do this, we will use the `cbSecure()` mixin provided by the `cbsecurity` module.  This returns an instance of the `CBSecurity` model.  You can find all of it's methods here: https://s3.amazonaws.com/apidocs.ortussolutions.com/coldbox-modules/cbsecurity/3.5.0/models/CBSecurity.html

```java
function login( event, rc, prc ){
    param rc.username = "";
    param rc.password = "";

    // This can throw a InvalidCredentials exception which is picked up by the REST handler
    var token = jwtAuth().attempt( rc.username, rc.password );

    event
        .getResponse()
        .setData( {
            "token" : token,
            "user"  : cbSecure().getUser().getMemento()
        } )
        .addMessage(
            "Bearer token created and it expires in #jwtAuth().getSettings().jwt.expiration# minutes"
        );
}
```

Wow, our handlers look so nice and tidy and with strange documentation!  However, we still need to build out our User Service that will power all this goodness.

Please check out all of the jwt service methods, there are tons of them and really helpful!

https://coldbox-security.ortusbooks.com/jwt/jwt-services


## User Service

Now to the next layer the models.  Our `User` object is already in place, but we need to update our `UserService` to support the authentication methods.  We will be using the `cbauth` module for this, so let's update our `UserService` to satisfy the `cbauth` contract.

In order for the jwt services and `cbauth` can authenticate and create tokens for us, we must adhere to the following interface (https://coldbox-security.ortusbooks.com/usage/authentication-services#user-services).  This is needed so the calls in our handlers can work correctly as the cbauth and jwt services will be calling our user services and leveraging our `User` object.

```js
interface{

	/**
	 * Verify if the incoming username/password are valid credentials.
	 *
	 * @username The username
	 * @password The password
	 */
	boolean function isValidCredentials( required username, required password );

	/**
	 * Retrieve a user by username
	 *
	 * @return User that implements JWTSubject and/or IAuthUser
	 */
	function retrieveUserByUsername( required username );

	/**
	 * Retrieve a user by unique identifier
	 *
	 * @id The unique identifier
	 *
	 * @return User that implements JWTSubject and/or IAuthUser
	 */
	function retrieveUserById( required id );
}
```

These are pre-generated for you with mock implementations.  You can find them in the [`UserService.cfc`](../src/models/UserService.cfc) in the `models` folder of the `api` module.  Let's do live coding:

```java
/**
    * Verify if the incoming username/password are valid credentials.
    *
    * @username The username
    * @password The password
    */
boolean function isValidCredentials( required username, required password ){
    var oTarget = retrieveUserByUsername( arguments.username );
    if ( !oTarget.isLoaded() ) {
        return false;
    }

    // Check Password Here: Remember to use bcrypt
    try {
        return variables.bcrypt.checkPassword( arguments.password, oTarget.getPassword() );
    } catch ( any e ) {
        return false;
    }
}

/**
    * Retrieve a user by username
    *
    * @return User that implements JWTSubject and/or IAuthUser
    */
function retrieveUserByUsername( required username ){
    return populator.populateFromStruct(
        new(),
        qb.from( "users" )
            .where( "username", arguments.username )
            .first()
    );
}

/**
    * Retrieve a user by unique identifier
    *
    * @id The unique identifier
    *
    * @return User that implements JWTSubject and/or IAuthUser
    */
User function retrieveUserById( required id ){
    return populator.populateFromStruct(
        new(),
        qb.from( "users" )
            .where( "id", arguments.id )
            .first()
    );
}
```

Ok we have finished all layers. Let's run our tests! Did it work? Why not?

## Seeders

As you can see, we have no users in our database.  We need to seed our database with a user so we can test our authentication.  Let's create a seeder for our users.  We will create a new seeder called `UserFixtures` in the `seeders`.

> Hint: Our mock generator is called `MockdataCFC` and is bundled with our `cfmigrations` and also with `TestBox`: https://github.com/ortus-solutions/mockdatacfc

Go to the shell and execute our seeder creation:

```bash
migrate seed create UserFixtures
```

Open the seeder: [resources/database/seeds/TestFixtures.cfc](../src/resources/database/seeds/UserFixtures.cfc).  The seeder method `run()` receives an instance of `qb` and `mockdata` so we can use for building out our database.

```java
// The bcrypt equivalent of the word test.
bcrypt_test = "$2a$12$5d31nX1hRnkvP/8QMkS/yOuqHpPZSGGDzH074MjHk6u2tYOG5SJ5W";

function run( qb, mockdata ) {
    qb.table( "users" ).insert(
        mockdata.mock(
            $num : 25,
            "id": "autoincrement",
            "firstName": "fname",
            "lastName": "lname",
            "username" : ( index ) => { "admin#index#" },
            "password": "oneOf:#bcrypt_test#"
        )
    );
}
```

This will populate the `users` table with 25 mocked users.  Please note that we use a `bcrypt_test`, this is the bcrypt equivalent of the word `test`.  How did we generate that?  Well here is a great online bcrypt generator: https://bcrypt.online/

To run this seeder, just do:

```bash
migrate seed run UserFixtures
```

And now we got data, verify the database that these records where created.

### Update Tests

Now that we know predictable data in our mock fixtures let's test against that.  Update the `login()` test in the `AuthSpec` to use the seeded user.

```java
given( "a valid username and password", function(){
    then( "I will be authenticated and will receive the JWT token", function(){
        // Use a user in the seeded db
        var event = this.post(
            route  = "/api/v1/login",
            params = {
                username : "admin1",
                password : "test"
            }
        );
        var response = event.getPrivateValue( "Response" );

        expect( response ).toHaveStatus( 200 );
        expect( response.getError() ).toBeFalse( response.getMessages().toString() );
        expect( response.getData() ).toHaveKey( "user" );
        expect( response.getData() ).toHaveKey( "token" );

        // debug( response.getData() );

        var decoded = jwtService.decode( response.getData().token );
        expect( decoded.sub ).toBe( 1 );
        expect( decoded.exp ).toBeGTE( dateAdd( "h", 1, decoded.iat ) );
        expect( decoded.sub ).toBe( response.getData().user.id );
    } );
} );

...

given( "a valid incoming jwt token", function(){
    then( "my token should become invalidated and I will be logged out", function(){
        // Log in first to get a valid token to logout with
        var token   = jwtService.attempt( "admin1", "test" );
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
```
