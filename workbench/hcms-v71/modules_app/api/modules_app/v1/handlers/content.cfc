/**
 * I am a new handler
 * Implicit Functions: preHandler, postHandler, aroundHandler, onMissingAction, onError, onInvalidHTTPMethod
 */
component extends="coldbox.system.RestHandler" secured{

	property name="contentService" inject="ContentService";

	/**
	 * Lists all content in the system
	 */
	function index( event, rc, prc ){
        event.getResponse()
            .setData(
				contentService
					.list()
					.map( (item) => item.getMemento() )
			 )
	}
	/**
	 * Create a new content object
	 */
	function create( event, rc, prc ){
		// Populate, validate and save the content object
		prc.response.setData(
			populateModel( "Content"  )
				.setUser( jwtAuth().getUser() )
				.validateOrFail()
				.save()
				.getMemento()
		);
	}
	/**
	 * Get a content object by its slug
	 */
	function show( event, rc, prc ){
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
        event.getResponse()
            .setData( {} )
            .addMessage( "Calling content/update" );
	}
	/**
	 * delete
	 */
	function delete( event, rc, prc ){
        event.getResponse()
            .setData( {} )
            .addMessage( "Calling content/delete" );
	}


}
