/**
 * My RESTFul Event Handler which inherits from the module `api`
 */
component extends="api.handlers.BaseHandler"{

	// DI
	property name="userService"	inject="UserService";

	/**
	 * Register a new user in our system
	 */
	function create( event, rc, prc ){
		// populate, validate and create
		prc.oUser = userService.create(
			validateOrFail( populateModel( "User" ) )
		);

		// Respond back with user rep and token
		prc.response.setData( {
			"user" 	: prc.oUser.getMemento(),
			"token"	: jwtAuth().fromUser( prc.oUser )
		} );
	}

}