# Step 11 - Updating Content

```js
story( "I want to be able to update content objects" )
```

I don't have to do any more setup for security, resources or even handlers.  We have our resourceful handler already.  So let's delve into the BDD first.

## BDD

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
                    slug : "",
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

## Update Action

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
        populateModel( prc.oContent )
            .setUser( jwtAuth().getUser() )
            .validateOrFail()
    );

	prc.response.setData( prc.oContent.getMemento() );
}
```

We have to also get the authenticated user to add it into the content.

## Update Services

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

## Updating The Unique Validator

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

### Let's go simple

Now let's go simple and update our validator to this:

```js
slug  : {
    required : true,
    unique : { table : "content" }
},
```

ColdBox Validations to the rescue!
