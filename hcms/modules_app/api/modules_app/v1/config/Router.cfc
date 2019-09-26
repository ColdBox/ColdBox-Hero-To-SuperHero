component{

    function configure(){

		route( "/", "echo.index" );

		resources( resource="registration", only="create" );

		post( "/login", "auth.login" );
		post( "/logout", "auth.logout" );

		// Invalid Routes
		route( "/:anything", "echo.onInvalidRoute" );

        //route( "/:handler/:action" ).end();
    }

}
