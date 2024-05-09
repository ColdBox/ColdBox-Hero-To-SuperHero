/**
 * 	ColdBox Integration Test
 *
 * 	The 'appMapping' points by default to the '/root ' mapping created in  the test folder Application.cfc.  Please note that this
 * 	Application.cfc must mimic the real one in your root, including ORM  settings if needed.
 *
 *	The 'execute()' method is used to execute a ColdBox event, with the  following arguments
 *	- event : the name of the event
 *	- private : if the event is private or not
 *	- prePostExempt : if the event needs to be exempt of pre post interceptors
 *	- eventArguments : The struct of args to pass to the event
 *	- renderResults : Render back the results of the event
 *
 * You can also use the HTTP executables: get(), post(), put(), path(), delete(), request()
 **/
 component extends="tests.resources.BaseIntegrationSpec" {

	property name="jwtService" inject="provider:JwtService@cbsecurity";
	property name="cbauth"     inject="provider:authenticationService@cbauth";

	/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "content Suite", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
				// Need to login
				jwt = jwtService.attempt( "admin1", "test" );
				getRequestContext().setValue( "x-auth-token", jwt );
			});

			story( "I want to be able to see content with different options", function(){
				it( "should display all content using the default options", function(){
					var event = get( route = "/api/v1/content" );
					var response = event.getPrivateValue( "Response" );
					expect( response ).toHaveStatus( 200 );
					expect( response.getData() ).toBeArray();
				});
			});

			story( "I want to see a single content object via a nice slug", function(){
				given( "a valid slug", function(){
					then( "I should be able to display the content object", function(){
						var testSlug = "content-slug-4";
						var event = get( route = "/api/v1/content/#testSlug#" );
						var response = event.getPrivateValue( "Response" );

						debug( response.getMessages() );

						expect( response ).toHaveStatus( 200 );
						expect( response.getData() ).toBeStruct();
						expect( response.getData().slug ).toBe( testSlug );
					});
				});

				given( "an invalid slug", function(){
					then( "then we should get a 404", function(){
						var testSlug = "invalid-bogus-object";
						var event = get( route = "/api/v1/content/#testSlug#" );
						var response = event.getPrivateValue( "Response" );

						debug( response.getMessages() );

						expect( response ).toHaveStatus( 404 );
					});
				});
			});
		});

	}

}
