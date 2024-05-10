component {

	function configure(){
		// API Echo
		get( "/", "Echo.index" );

		// API Authentication Routes
		post( "/login", "Auth.login" );
		post( "/logout", "Auth.logout" );
		post( "/register", "Auth.register" );

		// API Secured Routes
		get( "/whoami", "Echo.whoami" );

		// Content
		apiResources( resource="content", parameterName="slug" );

		// Invalid Routes
		route( "/:anything", "echo.onInvalidRoute" );
	}

}
