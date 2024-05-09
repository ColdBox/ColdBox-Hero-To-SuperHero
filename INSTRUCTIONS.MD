### Security

Now that we have our handler generated, we will secure it using a rule. Open the `config/ColdBox.cfc` and add the following rule to the `cbsecurity.rules` array:

```
{
	secureList 	: "v1:content"
}
```

That's it!  Now any requests made to that secure pattern will be inspected by the JWT Validator and a bearer token must be valid to access it!  BOOM!

You can also secure using annotations, we can get rid of the rule and then in our handler we can add the `secured` annotation to the `component` definition.  Same Approach.

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
