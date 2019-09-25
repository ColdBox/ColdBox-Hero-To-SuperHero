/**
* I am a new handler
*/
component extends="api.handlers.BaseHandler"{

	/**
     * Login to our system
     */
	function login( event, rc, prc ){
		param rc.username = "";
		param rc.password = "";

        prc.response
            .setData( jwtAuth().attempt( rc.username, rc.password ) )
            .addMessage( "Bearer token created and it expires in #jwtAuth().getSettings().jwt.expiration# minutes" );
    }

    /**
     * Logout of our system
     */
    function logout( event, rc, prc ){
        jwtAuth().logout();
        prc.response.addMessage( "Successfully logged out, token invalidated" );
	}

}