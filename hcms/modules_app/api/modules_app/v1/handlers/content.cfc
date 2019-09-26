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
		event.setView( "content/create" );
	}

	/**
	* show
	*/
	function show( event, rc, prc ){
		param rc.id = "";

		prc.oContent = contentService.findBySlug( rc.id );

		if( !prc.oContent.isLoaded() ){
			prc.response
				.setError( true )
				.setStatusCode( STATUS.NOT_FOUND )
				.setStatusText( "Not Found" )
				.addMessage( "The requested content object (#rc.id#) could not be found" );
			return;
		}

		prc.response.setData(
			prc.oContent.getMemento()
		);
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
