# Step 9 - Listing Content

Ok, we have all the building blocks for now focusing on our first content stories:

```js
story( "In order to interact with content in the CMS you must be authenticated" );
story( "I want to see content with different filtering options" )
story( "I want to see a single content object via a nice slug" )
```

Ok, let's start by modeling our content object.

## Content.cfc

We will be creating a `Content.cfc` that will store our headless content:

* `id`
* `slug` - URL safe title for the content entry, example: "my-first-blog-post"
* `title` - The title of the content, example: "My First Blog Post"
* `body`
* `isPublished:boolean`
* `publishedDate:date`
* `createdDate:date`
* `modifiedDate:date`
* `user (many to one)`

Ok, let's creat it via CommandBox

```bash
coldbox create model name="Content" properties="id,slug,title,body,isPublished:boolean,publishedDate:date,createdDate:date,modifiedDate:date,FK_userID,user" --migration --seeder --service
```

This is the output

```bash
 INFO   Created Model: [src/models//Content.cfc]
 INFO   Created Migration: [src/resources/database/migrations//2024_05_09_214321_create_contents_table.cfc]
 INFO   Created Seeder: [src/resources/database/seeds//contents.cfc]
 INFO   Created Service [src/models//ContentService.cfc]
 INFO   Created Test: [src/tests/specs/unit//ContentServiceTest.cfc]
 INFO   Created Test: [src/tests/specs/unit//ContentTest.cfc]
```

Open up the object and the companion unit test so we can:

* Update the path to `models.Content` etc.
* Initialize the content object
* Add an `isLoaded()` to verify persistence
* Add a `getUser()` to retrieve the relationship, so we will need to inject the `UserService`
* Add the mementifier instructions
* Add the validation constraints

```js
/**
* I am a new Model Object
*/
component
	accessors="true"
    transientCache="false"
	delegates     ="Validatable@cbvalidation,Population@cbDelegates"
{

	// inject the user service
	property name="userService" inject="UserService";
	property name="qb" inject="provider:QueryBuilder@qb";

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
            "id",
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
        if( isSimpleValue( arguments.user ) ){
			variables.FK_userId = arguments.user;
			return this;
		}

		if( arguments.user.isLoaded() ){
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
        expect( model.isLoaded() ).toBeFalse()
	});

});
```

Verify we can compile by running your tests!

## Update the `content` migration

Running our `create model` command created a seeder and a migration for us. However, it's not perfect, let's update the migration to include much more detail:

```java
component {

    function up( schema, queryBuilder ) {
        schema.create( "content", function( table ){
            table.increments( "id" );
            table.timestamps();
            table.string( "slug" ).unique();
            table.string( "title" );
            table.longText( "body" );
            table.boolean( "isPublished" ).default( false );
            table.datetime( "publishedDate" ).nullable();
            table.unsignedInteger( "FK_userID" );
            table.foreignKey( "FK_userID" ).references( "id" ).onTable( "users" );
            table.index( [ "isPublished", "publishedDate" ], "idx_publishing" );
        } );
    }

    function down( schema, queryBuilder ) {
        schema.dropIfExists( "content" );
    }

}
```

Run the migration:

```sh
migrate up
```

## Update the `content` seeder

The seeder also got created. Let's rename it to be consistent to `ContentFixtures` and update the data:

```java
/**
 * See https://forgebox.io/view/mockdatacfc
 */
component {

    function run( qb, mockdata ) {
		var aContent = mockdata.mock(
			$num = 25,
			"id": "autoincrement",
			"slug" : ( index ) => { return "content-slug-" & index; },
			"title" : "sentence",
			"body" : "baconlorem",
			"isPublished" : "oneof:1:0",
			"publishedDate" = "datetime",
			"FK_userID" = "num:25"
		).map( function( row ) {
			row.publishedDate = {
				value : dateTimeFormat( row.publishedDate, "iso8601" ),
				sqltype : "timestamp"
			}
			return row;
		} );

		//writedump( var: aContent, output : "console" );

		qb.table( "content" ).insert( aContent );
    }

}
```

Then run it:

```java
migrate seed run ContentFixtures
```


### BDD

>https://coldbox.ortusbooks.com/the-basics/routing/routing-dsl/resourceful-routes

Now that we have our model let's start with the stories and integration. We can create a nice ColdBox resource for our content: `resources( "content" )` and it will provide us with the following:

* `GET:content.index` 			: Display all content objects
* `POST:content.create` 		: Create a content object
* `GET:content.show` 			: Display a single content
* `PUT/PATCH:content.update` 	: Update a content object
* `DELETE:content.delete` 		: Remove a content object

```bash
coldbox create handler name="content" directory=modules_app/api/modules_app/v1/handlers views=false rest=true resource=true
```

Let's open up the specs and start building it out:

```js
/**
 * 	ColdBox Integration Test
 *
 * 	The 'appMapping' points by default to the '/root ' mapping created in  the test folder Application.cfc.  Please note that this
 * 	Application.cfc must mimic the real one in your root, including ORM  settings if needed.
 *
 *	The 'execute()' method is used to execute a ColdBox event, with the  following arguments
 *	- event : the name of the event
 *	- private : if the event is private or not
 *	- prePostExempt : if the event needs to be exempt of pre post interceptors
 *	- eventArguments : The struct of args to pass to the event
 *	- renderResults : Render back the results of the event
 *
 * You can also use the HTTP executables: get(), post(), put(), path(), delete(), request()
 **/
component extends="tests.resources.BaseIntegrationSpec" {

	/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "Content Suite", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();

				// Log in as the default user
			});

			story( "I want to see all the content with different filtering options", () => {
                given( "The default options", () => {
					then( "I should get an array of content items", () => {
						// Execute event or route via GET http method. Spice up accordingly
						var event = get( "/api/v1/contents" )
						var response = event.getResponse()

						// Validate the results
						debug( response.getData() )
						expect( response ).toHaveStatus( 200 )
						expect( response.getData() ).notToBeEmpty();
					})
				} )

				given( "Pagination options", ()=> {
					then( "I should get an array of paginated content items", () => {
					})
				})
			});

			story( "I want to see a single content object via a nice slug", () => {
				given( "A valid slug", () => {
					then( "I should get a single content object", () => {
						var event = get( "/api/v1/contents/content-slug-4" )
						var response = event.getResponse()

						// Validate the results
						expect( response ).toHaveStatus( 200 )
						expect( response.getData() ).toBeStruct();
						expect( response.getData().slug ).toBe( "content-slug-4" );
					})
				})

				given( "An invalid slug", () => {
					then( "I should get a 404 response", () => {
						var event = get( "/api/v1/contents/invalid-slug" )
						var response = event.getResponse()

						// Validate the results
						expect( response ).toHaveStatus( 404 )
					})
				})
			});


		});

	}

}
```

### Routing

Let's add our routing as we explained above in our `v1` router.

```js
apiResources( resource="content", parameterName="slug" );
```

Please note that we change the parameter name to `slug` since we will use those unique slugs for operation and not the Id.


### Event Handler

Now let's build out the handler that can satisfy our previous stories: `index` and `show`.

```js
/**
* I am a new handler
*/
component extends="coldbox.system.RestHandler" {

	property name="contentService";

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
	 * show
	 */
	function show( event, rc, prc ) {
		param rc.slug = "";

		prc.oContent = contentService.findBySlug( rc.slug );

		if ( !prc.oContent.isLoaded() ) {
			prc.response
				.setError( true )
				.setStatusCode( event.STATUS.NOT_FOUND )
				.addMessage( "The requested content object (#rc.slug#) could not be found" );
			return;
		}

		prc.response.setData( prc.oContent.getMemento() );
	}

}
```

### Content Services

Ok, now we need to focus on our Content Services that will power the handler since we already created the Content object, so we need to implement the `findBySlug(), get(), list()` methods:

```js
/**
 * Manage content in the system
 */
component singleton {

	// DI
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
	 * List all content
     *
	 * @orderBy The field to order by default is publishedDate
	 * @orderType The order type (asc or desc) default is asc
	 *
	 * @return array
	 */
	array function list( orderBy="publishedDate", orderType="asc" ){
		return qb
			.from( "content" )
			.orderBy( arguments.orderBy, arguments.orderType )
			.get()
			.map( ( content ) => {
				return populator.populateFromStruct(
					target : new(),
					memento : content,
					ignoreTargetLists : true
				);
			} );
	}

	/**
	 * Get a content by id
	 *
	 * @id The id of the content
	 *
	 * @return A persisted Content or an empty one
	 */
	function get( required id ){
		return populator.populateFromStruct(
            target : new(),
            memento : qb.from( "content" ).where( "id" , arguments.id ).first(),
			ignoreTargetLists : true
        );
	}

	/**
	 * Find by slug
	 *
	 * @slug The slug of the content
	 *
	 * @return A persisted Content or an empty one
	 */
	function findBySlug( required slug ){
		return populator.populateFromStruct(
            target : new(),
            memento : qb.from( "content" ).where( "slug" , arguments.slug ).first(),
			ignoreTargetLists : true
        );
	}

}
```

Ok, it seems we are done, let's run our tests and make sure we are listing all content and getting a single content.

**Extra Credit:** Leverage postman to test these endpoints. Remember you must get a jwt token first!


### Security

Now that we have our first content handler generated, we will secure it using a rule. Open the `config/modules/cbsecurity.cfc` and add the following rule to the firewall rules:

```js
// You can store all your rules in this inline array
"inline"   : [
    { secureList 	: "v1:content" }
],
```

That's it!  Now any requests made to that secure pattern will be inspected by the JWT Validator and a bearer token must be valid to access it!  BOOM!

Now secure the security visualizer as well:

```js
visualizer : {
    "enabled"      : true,
    "secured"      : true,
    "securityRule" : {}
},
```

You can also secure using annotations, we can get rid of the rule and then in our handler we can add the `secured` annotation to the `component` definition.  Same Approach, try it and report back.
