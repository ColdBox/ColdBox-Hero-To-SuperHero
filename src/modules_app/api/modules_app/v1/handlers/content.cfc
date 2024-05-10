/**
 * I am a new handler
 * Implicit Functions: preHandler, postHandler, aroundHandler, onMissingAction, onError, onInvalidHTTPMethod
 */
component extends="coldbox.system.RestHandler"{

	// DI
	property name="contentService" inject="ContentService";

	/**
	 * index
	 */
	function index( event, rc, prc ){
        prc.response.setData(
			contentService
				.list()
				.map( ( item ) => {
					return item.getMemento();
				} )
		);
	}

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
	/**
	 * show
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
