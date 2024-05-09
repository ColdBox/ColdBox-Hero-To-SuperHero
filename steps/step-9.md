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

## Update the `content` migration

Running our `create model` command created a seeder and a migration for us. However, it's not perfect, let's update the migration to include much more detail:

```java
component {

    function up( schema, queryBuilder ) {
        schema.create( "content", function( table ){
            table.increments( "id" );
            table.string( "slug" ).unique();
            table.string( "title" );
            table.longText( "body" );
            table.boolean( "isPublished" ).default( false );
            table.datetime( "publishedDate" ).nullable();
            table.timestamp( "createdDate" );
            table.timestamp( "modifiedDate" );
            table.unsignedInteger( "FK_userID" );
            table.foreignKey( "FK_userID" ).references( "id" ).onTable( "users" );
            table.index( [ "isPublished", "publishedDate" ], "idx_publishing" );
        } );
    }

    function down( schema, queryBuilder ) {
        schema.drop( "content" );
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
				cfsqltype : "timestamp"
			}
			return row;
		} );

		//writedump( var: aContent, output : "console" );

		qb.table( "contents" ).insert( aContent );
    }

}
```

Then run it:

```java
migrate seed run ContentFixtures
```


### BDD

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
{
	secureList 	: "v1:content"
}
```

That's it!  Now any requests made to that secure pattern will be inspected by the JWT Validator and a bearer token must be valid to access it!  BOOM!

You can also secure using annotations, we can get rid of the rule and then in our handler we can add the `secured` annotation to the `component` definition.  Same Approach, try it and report back.
