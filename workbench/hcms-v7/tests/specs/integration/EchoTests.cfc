﻿/*******************************************************************************
 *	Integration Test as BDD (CF10+ or Railo 4.1 Plus)
 *
 *	Extends the integration class: coldbox.system.testing.BaseTestCase
 *
 *	so you can test your ColdBox application headlessly. The 'appMapping' points by default to
 *	the '/root' mapping created in the test folder Application.cfc.  Please note that this
 *	Application.cfc must mimic the real one in your root, including ORM settings if needed.
 *
 *	The 'execute()' method is used to execute a ColdBox event, with the following arguments
 *	* event : the name of the event
 *	* private : if the event is private or not
 *	* prePostExempt : if the event needs to be exempt of pre post interceptors
 *	* eventArguments : The struct of args to pass to the event
 *	* renderResults : Render back the results of the event
 *******************************************************************************/
component extends="tests.resources.BaseIntegrationSpec"{

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "My RESTFUl Service", function(){
			beforeEach( function( currentSpec ){
				// Setup as a new ColdBox request, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
			} );

			it( "can handle global exceptions", function(){
				var event = execute(
					event          = "v1:echo.onError",
					renderResults  = true,
					eventArguments = {
						exception : {
							message    : "unit test",
							detail     : "unit test",
							stacktrace : ""
						}
					}
				);

				var response = event.getPrivateValue( "response" );
				expect( response.getError() ).toBeTrue();
				expect( response.getStatusCode() ).toBe( 500 );
			} );

			it( "can handle an echo", function(){
				var event    = this.request( "/api/v1" );
				var response = event.getPrivateValue( "response" );
				expect( response.getError() ).toBeFalse();
				expect( response.getData() ).toBe( "Welcome to my ColdBox RESTFul Service" );
			} );

			it( "can handle missing actions", function(){
				var event    = this.request( "/api/v1/echo/bogus" );
				var response = event.getPrivateValue( "response" );
				expect( response.getError() ).tobeTrue();
				expect( response.getStatusCode() ).toBe( 404 );
			} );
		} );
	}

}
