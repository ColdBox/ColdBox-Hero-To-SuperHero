/**
* I am a new handler
*/
component extends="api.handlers.BaseHandler"{

	property name="contentService" inject="ContentService";

	/**
	* index
	*/
	function index( event, rc, prc ){
		prc.response.setData(
			contentService.list()
				.map( ( item ) => { return item.getMemento(); } )
		);
	}

	/**
	* create
	*/
	function create( event, rc, prc ){

		// populate, validate and create
		prc.oContent = contentService.create(
			validateOrFail(
				populateModel( "Content" )
					.setUser( jwtAuth().getUser() )
			)
		);

		prc.response.setData( prc.oContent.getMemento() );
	}

	/**
	* update
	*/
	function update( event, rc, prc ){
		param rc.slug = "";

		prc.oContent = contentService.findBySlug( rc.slug );

		if( !prc.oContent.isLoaded() ){
			prc.response
				.setError( true )
				.setStatusCode( STATUS.NOT_FOUND )
				.setStatusText( "Not Found" )
				.addMessage( "The requested content object (#rc.slug#) could not be found" );
			return;
		}

		// populate, validate and create
		prc.oContent = contentService.update(
			validateOrFail(
				populateModel( prc.oContent )
					.setUser( jwtAuth().getUser() )
			)
		);

		prc.response.setData( prc.oContent.getMemento() );
	}

	/**
	* show
	*/
	function show( event, rc, prc ){
		param rc.slug = "";

		prc.oContent = contentService.findBySlug( rc.slug );

		if( !prc.oContent.isLoaded() ){
			prc.response
				.setError( true )
				.setStatusCode( STATUS.NOT_FOUND )
				.setStatusText( "Not Found" )
				.addMessage( "The requested content object (#rc.slug#) could not be found" );
			return;
		}

		prc.response.setData(
			prc.oContent.getMemento()
		);
	}

	/**
	* delete
	*/
	function delete( event, rc, prc ){
		param rc.slug = "";

		prc.oContent = contentService.findBySlug( rc.slug );

		if( !prc.oContent.isLoaded() ){
			prc.response
				.setError( true )
				.setStatusCode( STATUS.NOT_FOUND )
				.setStatusText( "Not Found" )
				.addMessage( "The requested content object (#rc.slug#) could not be found" );
			return;
		}

		// populate, validate and create
		contentService.delete( prc.oContent );

		prc.response.addMessage( "Content deleted!" );
	}

}