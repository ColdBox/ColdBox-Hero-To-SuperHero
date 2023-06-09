component{

    function configure(){

		route( "/", "echo.index" );
		route( "/echo/:action?" ).toHandler( "echo" );

		resources( resource="registration", only="create" );
		resources( resource="content", parameterName="slug" );

		post( "/login", "auth.login" );
		post( "/logout", "auth.logout" );

		// Invalid Routes
		route( "/:anything", "echo.onInvalidRoute" );

        //route( "/:handler/:action" ).end();
    }

}
