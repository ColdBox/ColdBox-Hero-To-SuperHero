# Step 12 - Removing Content

```js
story( "I want to be able to remove content objects" )
```

## BDD

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

## Delete Action

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

## Delete Services

Now to the SQL

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
