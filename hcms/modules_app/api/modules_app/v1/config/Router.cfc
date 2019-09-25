component{

    function configure(){

		route( "/", "echo.index" );

		resources( resource="registration", only="create" );

        route( "/:handler/:action" ).end();
    }

}
