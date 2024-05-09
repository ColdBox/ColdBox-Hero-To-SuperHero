
## Authentication

Now that we have registration complete, let's focus on authentication for our API.  Here are two stories to start with which can be found already in our auth spec.

```java
story( "I want to be able to authenticate with a username/password and receive a JWT token", function(){

} );

story( "I want to be able to logout from the system using my JWT token", function(){

} );
```

### BDD

Let's start with our BDD specs before we move to the implementation phase. Let's open the `AuthTests` spec and revise our login/logout tests so they use our new model and matchers:

```js
component extends="tests.resources.BaseIntegrationSpec" {

	property name="jwtService" inject="provider:JwtService@cbsecurity";
	property name="cbauth"     inject="provider:authenticationService@cbauth";

	/*********************************** BDD SUITES ***********************************/

	function run() {
		describe( "RESTFul Authentication", function() {
			beforeEach( function( currentSpec ) {
				// Setup as a new ColdBox request, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();

				// Make sure nothing is logged in to start our calls
				cbauth.logout();
				jwtService.getTokenStorage().clearAll();
			} );

			story( "I want to authenticate a user and receive a JWT token", function() {
				given( "a valid username and password", function() {
					then( "I will be authenticated and will receive the JWT token", function() {
						// Use a user in the seeded db
						var event = this.post(
							route  = "/api/v1/login",
							params = {
								username : "Milkshake10",
								password : "test"
							}
						);
						var response = event.getPrivateValue( "Response" );
						debug( response.getData() );

						expect( response ).toHaveStatus( 200 );
						expect( response.getData() ).toHaveKey( "token,user" );

						var decoded = jwtService.decode( response.getData().token );
						expect( decoded.sub ).toBe( 10 );
						expect( decoded.exp ).toBeGTE( dateAdd( "h", 1, decoded.iat ) );
						expect( decoded.sub ).toBe( response.getData().user.id );
					} );
				} );
				given( "invalid email and password", function() {
					then( "I will receive a 401 exception ", function() {
						var event = this.post(
							route  = "/api/v1/login",
							params = {
								email    : "invalid",
								password : "invalid"
							}
						);
						var response = event.getPrivateValue( "Response" );
						expect( response ).toHaveStatus( 401 );
					} );
				} );
			} );

			story( "I want to register into the system", function() {
				given( "valid registration details", function() {
					then( "I should register, log in and get a token", function() {
						// Use a user in the seeded db
						var event = this.post(
							route  = "/api/v1/register",
							params = {
								name     : "luis Majano",
								email    : "lmajano@coldbox.org",
								username : "lmajano",
								password : "lmajano"
							}
						);
						var response = event.getPrivateValue( "Response" );

						debug( response.getData() );

						expect( response ).toHaveStatus( 200 );
						expect( response.getData() ).toHaveKey( "token,user" );

						var decoded = jwtService.decode( response.getData().token );
						expect( decoded.sub ).toBe( response.getData().user.id );
						expect( decoded.exp ).toBeGTE( dateAdd( "h", 1, decoded.iat ) );
					} );
				} );
				given( "invalid registration details", function() {
					then( "I should get an error message", function() {
						var event = this.post(
							route  = "/api/v1/register",
							params = {
								email    : "invalid",
								password : "invalid"
							}
						);
						var response = event.getPrivateValue( "Response" );
						expect( event.getResponse() ).toHaveStatus( 400 );
					} );
				} );
				xgiven( "valid registration data but with a non-unique username", function() {
					then( "a validation message should be sent to the user with an error message", function() {
					} );
				} );
			} );

			story( "I want to be able to logout from the system using my JWT token", function() {
				given( "a valid incoming jwt token", function() {
					then( "my token should become invalidated and I will be logged out", function() {
						// Log in first to get a valid token to logout with
						var token   = jwtService.attempt( "Milkshake10", "test" );
						var payload = jwtService.decode( token );
						expect( cbauth.isLoggedIn() ).toBeTrue();

						// Now Logout
						var event = this.post( route = "/api/v1/logout", params = { "x-auth-token" : token } );

						var response = event.getPrivateValue( "Response" );
						expect( response ).toHaveStatus( 200 );
						expect( cbauth.isLoggedIn() ).toBeFalse();
					} );
				} );
				given( "an invalid incoming jwt token", function() {
					then( "I should see an error message", function() {
						// Now Logout
						var event = this.post( route = "/api/v1/logout", params = { "x-auth-token" : "123" } );

						var response = event.getPrivateValue( "Response" );
						expect( response.getError() ).toBeTrue( response.getMessages().toString() );
						expect( response ).toHaveStatus( 500 );
					} );
				} );
			} );
		} );
	}

}
```

### Routing

Open the `v1` module's router: `modules_app/api/modules_app/v1/config/Router.cfc` and make sure our login/logout routes are there:

```js
component {

	function configure() {
		// API Echo
		get( "/", "Echo.index" );

		// API Authentication Routes
		post( "/login", "Auth.login" );
		post( "/logout", "Auth.logout" );
		post( "/register", "Auth.register" );

		// API Secured Routes
		get( "/whoami", "Echo.whoami" );


		route( "/:handler/:action" ).end();
	}

}

```

Issue a `coldbox reinit` and check out the Route Visualizer: http://127.0.0.1:42518/route-visualizer

### Event Handler

Let's go back to our `auth` handler and finalize the login/logout actions.

```js
/**
 * Authentication Handler
 */
component extends="coldbox.system.RestHandler" {

	// Injection
	property name="userService" inject="UserService";

	/**
	 * Login a user into the application
	 *
	 * @x-route (POST) /api/v1/login
	 * @requestBody ~api/v1/auth/login/requestBody.json
	 * @response-default ~api/v1/auth/login/responses.json##200
	 * @response-401 ~api/v1/auth/login/responses.json##401
	 */
	function login( event, rc, prc ) {
		param rc.username = "";
		param rc.password = "";

		prc.token = jwtAuth().attempt( rc.username, rc.password );

		prc.response
			.setData( {
				"token" : prc.token,
				"user"  : cbSecure()
					.getAuthService()
					.getUser()
					.getMemento()
			} )
			.addMessage( "Bearer token created and it expires in #jwtAuth().getSettings().jwt.expiration# minutes" );
	}

	/**
	 * Register a new user in the system
	 *
	 * @x-route (POST) /api/v1/register
	 * @requestBody ~api/v1/auth/register/requestBody.json
	 * @response-default ~api/v1/auth/register/responses.json##200
	 * @response-400 ~api/v1/auth/register/responses.json##400
	 */
	function register( event, rc, prc ) {
		param rc.fname    = "";
		param rc.lname    = "";
		param rc.email    = "";
		param rc.password = "";

		// Populate, Validate, Create a new user
		prc.oUser = userService.create( validateOrFail( populateModel( "User" ) ) );

		// Log them in if it was created!
		event
			.getResponse()
			.setData( {
				"token" : jwtAuth().fromuser( prc.oUser ),
				"user"  : prc.oUser.getMemento()
			} )
			.addMessage(
				"User registered correctly and Bearer token created and it expires in #jwtAuth().getSettings().jwt.expiration# minutes"
			);
	}

	/**
	 * Logout a user
	 *
	 * @x-route (POST) /api/v1/logout
	 * @security bearerAuth,ApiKeyAuth
	 * @response-default ~api/v1/auth/logout/responses.json##200
	 * @response-500 ~api/v1/auth/logout/responses.json##500
	 */
	function logout( event, rc, prc ) {
		jwtAuth().logout();
		event.getResponse().addMessage( "Successfully logged out" )
	}

}
```

Wow, our handlers look so nice and tidy and with strange documentation!  However, we still need to build out our User Service that will power all this goodness.

Please check out all of the jwt service methods, there are tons of them and really helpful!

https://coldbox-security.ortusbooks.com/jwt/jwt-services

### UserService

In order for the jwt services and cbauth can authenticate and create tokens for us, we must adhere to the following interface (https://coldbox-security.ortusbooks.com/usage/authentication-services#user-services).  This is needed so the calls in our handlers can work correctly as the cbauth and jwt services will be calling our user services and leveraging our User object.

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

That's it.  The jwt services and cbauth will know how to put everything together for you.  So let's build the service out.

```js
/**
 * User Services
 */
component accessors="true" singleton {

	/**
	 * --------------------------------------------------------------------------
	 * DI
	 * --------------------------------------------------------------------------
	 */
	property name="populator" inject="wirebox:populator";
	property name="bcrypt"    inject="@BCrypt";
	property name="qb"        inject="provider:QueryBuilder@qb";

	/**
	 * Constructor
	 */
	function init() {
		return this;
	}

	/**
	 * Construct a new user object via WireBox
	 */
	User function new() provider="User";

	/**
	 * Create a new user in the system
	 *
	 * @user The user to create
	 *
	 * @return The created user
	 */
	User function create( required user ) {
		var qResults = qb
			.from( "users" )
			.insert(
				values = {
					"name"     : arguments.user.getName(),
					"email"    : arguments.user.getEmail(),
					"username" : arguments.user.getUsername(),
					"password" : bcrypt.hashPassword( arguments.user.getPassword() )
				}
			);

		// populate the id
		arguments.user.setId( qResults.result.generatedKey );

		return arguments.user;
	}

	/**
	 * Verify if the incoming username/password are valid credentials.
	 *
	 * @username The username
	 * @password The password
	 */
	boolean function isValidCredentials( required username, required password ) {
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
	function retrieveUserByUsername( required username ) {
		return populator.populateFromStruct(
			new (),
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
	User function retrieveUserById( required id ) {
		return populator.populateFromStruct(
			new (),
			qb.from( "users" )
				.where( "id", arguments.id )
				.first()
		);
	}

}
```

That's it!  Go run your tests and make sure all the tests pass!  What have you learned?

## Invalid Routes

Ok, so what would happen if we try to execute `/api/v1/bogus` in the browser?  Go and try it!

You will see that the browser blows up with a nasty invalid event. actually, ANY route we try to execute in the `v1` api will fail like this and this is not nice.  We want uniformity, so let's add a catch all route that issues the Rest Handler's `onInvalidRoute()` method.

Open the `v1` router and add the invalid routes catch all before the default route and actually remove the default route as we won't be using it.

```
// Invalid Routes
route( "/:anything", "echo.onInvalidRoute" );

//route( "/:handler/:action" ).end();
```

Issue a nice `coldbox reinit` and hit the route again or any invalid route and you should see a nice API return 404 message. Now, this is great, but we lost something? Anybody can guess?

> We lost all of our convention based routing which was below it.  This means, that we must register all the routes we want.

## Swagger

Ok, before we go any further building stuff out, let's go over the weird documentation in our handlers.  Go open one and try to decipher it? We are using cbswagger directives so we can document our API.  Go to http://127.0.0.1:42518/cbswagger and see the json created for you.  Copy it and go to https://editor.swagger.io/ and paste it in.

WOW! Our API is fully documented! What magic unicorn is this!

* https://www.forgebox.io/view/cbswagger
* https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md

### Customize It

Open your `config/ColdBox.cfc` and  under the `moduleSettings` there is a `cbSwagger` section. Let's update it a bit to match what we are building:

```js
cbswagger : {
	// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
	"routes"        : [ "api" ],
	// Any routes to exclude
	"excludeRoutes" : [ "api/v1/:anything/" ],
	// The default output format: json or yml
	"defaultFormat" : "json",
	// A convention route, relative to your app root, where request/response samples are stored ( e.g. resources/apidocs/responses/[module].[handler].[action].[HTTP Status Code].json )
	"samplesPath"   : "resources/apidocs",
	// Information about your API
	"info"          : {
		// A title for your API
		"title"       : "Hero to SuperHero Headless CMS",
		// A description of your API
		"description" : "A nice hmvc headless CMS",
		// The contact email address
		"contact"     : {
			"name"  : "API Support",
			"url"   : "https://www.swagger.io/support",
			"email" : "info@ortussolutions.com"
		},
		// A url to the License of your API
		"license" : {
			"name" : "Apache 2.0",
			"url"  : "https://www.apache.org/licenses/LICENSE-2.0.html"
		},
		// The version of your API
		"version" : "1.0.0"
	},
	// Tags
	"tags"         : [ ],
	// https://swagger.io/specification/#externalDocumentationObject
	"externalDocs" : {
		"description" : "Find more info here",
		"url"         : "https://blog.readme.io/an-example-filled-guide-to-swagger-3-2/"
	},
	// https://swagger.io/specification/#serverObject
	"servers" : [
		{
			"url"         : "https://mysite.com/v1",
			"description" : "The main production server"
		},
		{
			"url"         : "http://127.0.0.1:42518",
			"description" : "The dev server"
		}
	],
	// An element to hold various schemas for the specification.
	// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#componentsObject
	"components" : {
		// Define your security schemes here
		// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securitySchemeObject
		"securitySchemes" : {
			"ApiKeyAuth" : {
				"type"        : "apiKey",
				"description" : "User your JWT as an Api Key for security",
				"name"        : "x-api-key",
				"in"          : "header"
			},
			"bearerAuth" : {
				"type"         : "http",
				"scheme"       : "bearer",
				"bearerFormat" : "JWT"
			}
		}
	}

	// A default declaration of Security Requirement Objects to be used across the API.
	// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securityRequirementObject
	// Only one of these requirements needs to be satisfied to authorize a request.
	// Individual operations may set their own requirements with `@security`
	// "security" : [
	//	{ "APIKey" : [] },
	//	{ "UserSecurity" : [] }
	// ]
},
```

### Resources

You can also find all the resources we generated previously from our app template in the `resources/apidocs` folder. You will find here global schemas, and our routing by convention.  Let's explore them and update them accordingly since our model changed.

* Update all resources to match our new API structure.

### Fix our Error on SwaggerHub

You might see an error on top specifying the `{anything}` route we added. In all reality, this is an internal route, so we don't need it documented, so open your `config/Coldbox.cfc` and look for the `excludedRoutes` in the `cbSwagger` module settings:

```js
// Any routes to exclude
"excludeRoutes" : [ "api/v1/:anything/"],
```

Regenerate the swagger doc and we have our internal routing removed! Voila!

### PostMan Automation

Let's do one more mystical trick.  Copy the swagger json and open Postman. Look for the import and import our cbwagger.

WOW!  We know have imported all of our API into Postman for testing and even more sweet documentation!

## Listing Content

Ok, we have all the building blocks for now focusing on our first content stories:

```js
story( "In order to interact with content in the CMS you must be authenticated" );
story( "I want to see content with different filtering options" )
story( "I want to see a single content object via a nice slug" )
```

Ok, let's start by modeling our content object

### Content.cfc

We will be creating a `Content.cfc` that will store our headless content:

* `id`
* `slug`
* `title`
* `body`
* `isPublished:boolean`
* `publishedDate:date`
* `createdDate:date`
* `modifiedDate:date`
* `user (many to one)`

Ok, let's creat it via CommandBox

```bash
coldbox create model name="Content" properties="id,slug,title,body,isPublished:boolean,publishedDate:date,createdDate:date,modifiedDate:date,FK_userID,user"
```

Open up the object and the companion unit test.  Remember in our unit test, we just want quick verifications.

* Initialize the content object
* Add an `isLoaded()` to verify persistence
* Add a `getUser()` to retrieve the relationship, so we will need to inject the `UserService`
* Add the mementifier instructions
* Add the validation constraints

```js
/**
* I am a new Model Object
*/
component accessors="true"{

	// inject the user service
	property name="userService" inject="UserService";

	// Properties
	property name="id"            type="string";
	property name="slug"          type="string";
	property name="title"         type="string";
	property name="body"          type="string";
	property name="isPublished"   type="boolean";
	property name="publishedDate" type="date";
	property name="createdDate"   type="date";
	property name="modifiedDate"  type="date";
	property name="FK_userID"     type="string" default="";

	this.constraints = {
        slug    	: { required : true, udf : ( value, target ) => {
			if( isNull( arguments.value ) ) return false;
            return qb.from( "content" ).where( "slug", arguments.value ).count() == 0;
		}},
		title       : { required : true },
		body       	: { required : true },
		FK_userID	: { required : true }
	};

	this.memento = {
		defaultIncludes = [
			"slug",
			"title",
			"body",
			"isPublished",
			"publishedDate",
			"createdDate",
			"modifiedDate",
			"user.name",
			"user.email"
		],
		defaultExcludes = [
			"FK_userID",
			"user.id",
			"user.username",
			"user.modifiedDate",
			"user.createdDate"
		]
	};

	/**
	 * Constructor
	 */
	Content function init(){
		variables.createdDate 	= now();
		variables.modifiedDate 	= now();
		variables.isPublished 	= false;
		variables.FK_userID 	= "";
		return this;
	}

	boolean function isLoaded(){
		return ( !isNull( variables.id ) && len( variables.id ) );
	}

	User function getUser(){
		return variables.userService.retrieveUserById( variables.FK_userId );
	}

	Content function setUser( required user ){
		if( user.isLoaded() ){
			variables.FK_userId = arguments.user.getId();
		}
		return this;
	}

}
```

Update your tests:

```js
describe( "Content Object", function(){

	it( "can be created", function(){
		expect( model ).toBeComponent();
	});

});
```

Verify we can compile by running your tests!

### BDD

Now that we have our model let's start with the stories and integration. We can create a nice ColdBox resource for our content: `resources( "content" )` and it will provide us with the following:

* `GET:content.index` 			: Display all content objects
* `POST:content.create` 		: Create a content object
* `GET:content.show` 			: Display a single content
* `PUT/PATCH:content.update` 	: Update a content object
* `DELETE:content.delete` 		: Remove a content object

```bash
coldbox create handler name="content" actions="index,create,show,update,delete" directory=modules_app/api/modules_app/v1/handlers
```

Let's open up the specs and start building it out:

```js
describe( "Content Services: In order to interact with content in the CMS you must be authenticated", function(){

	beforeEach(function( currentSpec ){
		// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
		setup();
		// Need to login
		jwt = jwtService.attempt( "Milkshake10", "test" );
		getRequestContext().setValue( "x-auth-token", jwt );
	});

	story( "I want to be able to see content with different options", function(){
		it( "should display all content using the default options", function(){
			var event = get( route = "/api/v1/content" );
			var response = event.getPrivateValue( "Response" );
			expect( response ).toHaveStatus( 200 );
			expect( response.getData() ).toBeArray();
		});
	});

	story( "I want to see a single content object via a nice slug", function(){
		given( "a valid slug", function(){
			then( "I should be able to display the content object", function(){
				var testSlug = "Spoon-School-Staircase";
				var event = get( route = "/api/v1/content/#testSlug#" );
				var response = event.getPrivateValue( "Response" );

				debug( response.getMessages() );

				expect( response ).toHaveStatus( 200 );
				expect( response.getData() ).toBeStruct();
				expect( response.getData().slug ).toBe( testSlug );
			});
		});

		given( "an invalid slug", function(){
			then( "then we should get a 404", function(){
				var testSlug = "invalid-bogus-object";
				var event = get( route = "/api/v1/content/#testSlug#" );
				var response = event.getPrivateValue( "Response" );

				debug( response.getMessages() );

				expect( response ).toHaveStatus( 404 );
			});
		});
	});

} );
```

### Security

Now that we have our handler generated, we will secure it using a rule. Open the `config/ColdBox.cfc` and add the following rule to the `cbsecurity.rules` array:

```
{
	secureList 	: "v1:content"
}
```

That's it!  Now any requests made to that secure pattern will be inspected by the JWT Validator and a bearer token must be valid to access it!  BOOM!

You can also secure using annotations, we can get rid of the rule and then in our handler we can add the `secured` annotation to the `component` definition.  Same Approach.

### Routing

Let's add our routing as we explained above in our `v1` router.

```js
resources( resource="content", parameterName="slug" );
```

Please note that we change the parameter name to `slug` since we will use those unique slugs for operation and not the Id.

### Event Handler

Now let's build out the handler that can satisfy our previous stories

```js
/**
* I am a new handler
*/
component extends="coldbox.system.RestHandler" {

	property name="contentService" inject="ContentService";

	/**
	 * index
	 */
	function index( event, rc, prc ) {
		prc.response.setData(
			contentService
				.list()
				.map( ( item ) => {
					return item.getMemento();
				} )
		);
	}

	/**
	* create
	*/
	function create( event, rc, prc ){
		event.setView( "content/create" );
	}

	/**
	 * show
	 */
	function show( event, rc, prc ) {
		param rc.slug = "";

		prc.oContent = contentService.findBySlug( rc.slug );

		if ( !prc.oContent.isLoaded() ) {
			prc.response
				.setError( true )
				.setStatusCode( event.STATUS.NOT_FOUND )
				.setStatusText( "Not Found" )
				.addMessage( "The requested content object (#rc.slug#) could not be found" );
			return;
		}

		prc.response.setData( prc.oContent.getMemento() );
	}

	/**
	* update
	*/
	function update( event, rc, prc ){
		event.setView( "content/update" );
	}

	/**
	* delete
	*/
	function delete( event, rc, prc ){
		event.setView( "content/delete" );
	}

}
```

### Content Services

Ok, now we need to focus on our Content Services that will power the handler since we already created the Content object, so we need to implement the `findBySlug()` and the `list()` methods:

Let's generate what we need:

```js
coldbox create model name="ContentService" persistence="singleton" methods="list,get,findBySlug"
```

Also open the unit test and do a quick compile test:

```js
describe( "ContentService Suite", function(){

	it( "can be created", function(){
		expect( model ).toBeComponent();
	});

});
```

Now let's build it out:

```js
/**
* I am a new Model Object
*/
component singleton accessors="true"{

	// Properties
	property name="populator" 	inject="wirebox:populator";
	property name="qb"          inject="provider:QueryBuilder@qb";


	/**
	 * Constructor
	 */
	ContentService function init(){
		return this;
	}

	Content function new() provider="Content";

	/**
	* list
	*/
	array function list( orderBy="publishedDate", orderType="asc" ){
		return qb
			.from( "content" )
			.orderBy( arguments.orderBy, arguments.orderType )
			.get()
			.map( ( content ) => {
				return populator.populateFromStruct(
					new(),
					content
				);
			} );
	}

	/**
	* get
	*/
	function get( required id ){
		return populator.populateFromStruct(
            new(),
            qb.from( "content" ).where( "id" , arguments.id ).first()
        );
	}

	/**
	* Find by slug
	*/
	function findBySlug( required slug ){
		return populator.populateFromStruct(
            new(),
            qb.from( "content" ).where( "slug" , arguments.slug ).first()
        );
	}


}
```

Ok, it seems we are done, let's run our tests and make sure we are listing all content and getting a single content.

**Extra Credit:** Leverage postman to test these endpoints. Remember you must get a jwt token first!

## Creating Content

Ok, we can list all and one piece of content, let's try creating one now.

```js
story( "I want to be able to create content objects" )
```

I don't have to do any more setup for security, resources or even handlers.  We have our resourceful handler already.  So let's delve into the BDD first.

### BDD

Update the spec with a new story and scenarios:`


```js
story( "I want to be able to create new content objects", function(){
	given( "valid incoming data", function(){
		then( "it should create a new content object", function(){
			var event = post(
				route = "/api/v1/content",
				params = {
					slug          : "my-new-test-#createUUID()#",
					title         : "I love BDD",
					body          : "I love BDD sooooooooooo much!",
					isPublished   : true,
					publishedDate : now()
				}
			)

			// expectations go here.
			var response = event.getPrivateValue( "Response" );

			debug( response.getData() );

			expect( response ).toHaveStatus( 200 );
			expect( response.getData().title ).toBe( "I love BDD" );
			expect( response.getData().id ).notToBeEmpty();
		});
	});

	given( "invalid data", function(){
		then( "it should throw a validation error", function(){
			var event = post(
				route = "/api/v1/content",
				params = {
					body          : "I love BDD sooooooooooo much!",
					isPublished   : true,
					publishedDate : now()
				}
			)

			// expectations go here.
			var response = event.getPrivateValue( "Response" );

			expect( response ).toHaveStatus( 400 );
			expect( response ).toHaveInvalidData( "slug", "is required" );
		});
	});
});
```

Ok, now let's put it together!

### Create Action

```js
/**
* create
*/
function create( event, rc, prc ){

	// populate, validate and create
	prc.oContent = contentService.create(
		validateOrFail( populateModel( "Content" ).setUser( jwtAuth().getUser() ) )
	);

	prc.response.setData( prc.oContent.getMemento() );
}
```

We have to also get the authenticated user to add it into the content.

### Create Services

Now to the ugly (funky) SQL

```js
/**
* create
*/
function create( required content ){
	var qResults = qb.from( "content" )
		.insert( values = {
			"slug" 			= arguments.content.getSlug(),
			"title" 		= arguments.content.getTitle(),
			"body" 			= arguments.content.getBody(),
			"isPublished" 	= { value : arguments.content.getIsPublished(), cfsqltype : "tinyint" },
			"publishedDate" = { value : arguments.content.getPublishedDate(), cfsqltype : "timestamp" },
			"createdDate" 	= { value : now(), cfsqltype : "timestamp" },
			"modifiedDate" 	= { value : now(), cfsqltype : "timestamp" },
			"FK_userId"		= arguments.content.getUser().getId()
		} );

	// populate the id
	arguments.content.setId( qResults.result.generatedKey );

	return arguments.content;
}
```

Run your tests, validate and BOOM! Creation done! Next!


## Updating Content

```js
story( "I want to be able to update content objects" )
```

I don't have to do any more setup for security, resources or even handlers.  We have our resourceful handler already.  So let's delve into the BDD first.

### BDD

Update the spec with a new story and scenarios:`


```js
story( "I want to be able to update content objects", function(){
	given( "valid incoming data", function(){
		then( "it should update the content object", function(){
			var event = put(
				route = "/api/v1/content/Record-Slave-Crystal",
				params = {
					title         : "I just changed you!",
					body          : "I love BDD sooooooooooo much!",
					isPublished   : false
				}
			)

			// expectations go here.
			var response = event.getPrivateValue( "Response" );

			debug( response.getData() );

			expect( response ).toHaveStatus( 200 );
			expect( response.getData().title ).toBe( "I just changed you!" );
			expect( response.getData().id ).notToBeEmpty();
		});
	});

	given( "an invalid slug", function(){
		then( "it should throw a validation error", function(){
			var event = put(
				route = "/api/v1/content/bogus",
				params = {
					body          : "I love BDD sooooooooooo much!",
					isPublished   : true,
					publishedDate : now()
				}
			)

			// expectations go here.
			var response = event.getPrivateValue( "Response" );

			expect( response ).toHaveStatus( 404 );
		});
	});
});
```

Ok, now let's put it together!

### Update Action

```js
/**
 * update
 */
function update( event, rc, prc ) {
	param rc.slug = "";

	prc.oContent = contentService.findBySlug( rc.slug );

	if ( !prc.oContent.isLoaded() ) {
		prc.response
			.setError( true )
			.setStatusCode( event.STATUS.NOT_FOUND )
			.setStatusText( "Not Found" )
			.addMessage( "The requested content object (#rc.slug#) could not be found" );
		return;
	}

	// populate, validate and create
	prc.oContent = contentService.update(
		validateOrFail( populateModel( prc.oContent ).setUser( jwtAuth().getUser() ) )
	);

	prc.response.setData( prc.oContent.getMemento() );
}
```

We have to also get the authenticated user to add it into the content.

### Update Services

Now to the ugly (funky) SQL

```js
/**
* update
*/
function update( required content ){
	var qResults = qb.from( "content" )
		.whereId( arguments.content.getId() )
		.update( {
			"slug" 			= arguments.content.getSlug(),
			"title" 		= arguments.content.getTitle(),
			"body" 			= arguments.content.getBody(),
			"isPublished" 	= { value : arguments.content.getIsPublished(), cfsqltype : "tinyint" },
			"publishedDate" = { value : arguments.content.getPublishedDate(), cfsqltype : "timestamp" },
			"modifiedDate" 	= { value : now(), cfsqltype : "timestamp" },
			"FK_userId"		= arguments.content.getUser().getId()
		} );

	return arguments.content;
}
```

Run your tests, validate and BOOM, validation errors!!! WHATTTTTT. What could be wrong?

### Updating The Unique Validator

It seems our validator is in need of some updating, since if we do an update it will claim that the slug is already there, but I want an update not a creation.  So let's udpate it.

```js
slug : { required : true, udf : ( value, target ) => {
	if( isNull( arguments.value ) ) return false;
	return qb.from( "content" )
		.where( "slug", arguments.value )
		.when( this.isLoaded(), ( q ) => {
			arguments.q.whereNotIn( "id", this.getId() );
		} )
		.count() == 0;
}},
```

Check out the cool `when()` function. It allows us to switch up the SQL if the actual object has been persisted already. Now run your tests and we should be good now!


## Removing Content

```js
story( "I want to be able to remove content objects" )
```

### BDD

Update the spec with a new story and scenarios:`


```js
story( "I want to be able to remove content objects", function(){
	given( "a valid incoming slug", function(){
		then( "it should remove content object", function(){
			var event = DELETE(
				route = "/api/v1/content/Record-Slave-Crystal"
			);

			// expectations go here.
			var response = event.getPrivateValue( "Response" );

			debug( response.getData() );

			expect( response ).toHaveStatus( 200 );
			expect( response.getMessages().toString() ).toInclude( "Content deleted" );
		});
	});

	given( "an invalid slug", function(){
		then( "it should throw a validation error", function(){
			var event = delete(
				route = "/api/v1/content/bogus"
			);

			// expectations go here.
			var response = event.getPrivateValue( "Response" );

			expect( response ).toHaveStatus( 404 );
		});
	});
});
```

Ok, now let's put it together!

### Delete Action

```js
/**
* delete
*/
function delete( event, rc, prc ){
	param rc.slug = "";

	prc.oContent = contentService.findBySlug( rc.slug );

	if ( !prc.oContent.isLoaded() ) {
		prc.response
			.setError( true )
			.setStatusCode( event.STATUS.NOT_FOUND )
			.setStatusText( "Not Found" )
			.addMessage( "The requested content object (#rc.slug#) could not be found" );
		return;
	}

	// populate, validate and create
	contentService.delete( prc.oContent );

	prc.response.addMessage( "Content deleted!" );
}
```

### Delete Services

Now to the ugly (funky) SQL

```js
/**
 * delete
 */
function delete( required content ){
	var qResults = qb.from( "content" )
		.whereId( arguments.content.getId() )
		.delete();

	arguments.content.setId( "" );

	return arguments.content;
}
```

Run your tests!

## Where Do We Go From Here

We should be excited, exhausted, and amazed that we have started to build a headless CMS!  This is just the start, what else can we do? Here are some more ideas?

* Content Versioning
* Content Drafts
* Content Categories
* Move to an ORM (Hibernate or Quick)
* Allow creator and editor in content objects
* Pagination
* Search
* The list goes on!!!

Happy Coding!
