# Step 10 - Creating Content

Ok, we can list all and one piece of content, let's try creating one now.

```js
story( "I want to be able to create content objects" )
```

I don't have to do any more setup for security, resources or even handlers.  We have our resourceful handler already.  So let's delve into the BDD first.

## BDD

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
			expect( response.getData() ).toHaveKey( "slug" );
		});
	});
});
```

Ok, now let's put it together!

## Create Action

```js
/**
 * Create a new content object
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

## Create Services

Now to the services:

```js
/**
 * Create a new content object
 *
 * @content The content object to create
 *
 * @return The persisted content object
 */
function create( required content ){
    var qResults = qb.from( "content" )
        .insert( values = {
            "slug" 				 = arguments.content.getSlug(),
            "title" 			  = arguments.content.getTitle(),
            "body" 				= arguments.content.getBody(),
            "isPublished" 		 = { value : arguments.content.getIsPublished(), cfsqltype : "tinyint" },
            "publishedDate" 	= { value : arguments.content.getPublishedDate(), cfsqltype : "timestamp" },
            "createdDate" 		= { value : arguments.content.getCreatedDate(), cfsqltype : "timestamp" },
            "modifiedDate" 		= { value : arguments.content.getModifiedDate(), cfsqltype : "timestamp" },
            "FK_userId"			= arguments.content.getUser().getId()
        } );

    // populate the id
    arguments.content.setId( qResults.result.generatedKey );

    return arguments.content;
}
```

Run your tests, validate and BOOM! Creation done! Next!
