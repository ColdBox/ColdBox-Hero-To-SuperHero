component extends="tests.resources.BaseIntegrationSpec"{

	property name="jwtService" inject="provider:JwtService@cbsecurity";
	property name="cbauth" inject="provider:authenticationService@cbauth";

	/*********************************** BDD SUITES ***********************************/

	function run(){

		story( "I want to authenticate a user via username/password and receive a JWT token", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
			});

			given( "a valid username and password", function(){
				then( "I will be authenticated and will receive the JWT token", function(){
					// Use a user in the seeded db
					var event = post(
						route = "/api/v1/login",
						params = {
							username = "Milkshake10",
							password = "test"
						}
					);
					var response = event.getPrivateValue( "Response" );
					expect( response.getError() ).toBeFalse( response.getMessages().toString() );
					expect( response.getData() ).toBeString();

					debug( response.getData() );

					var decoded = jwtService.decode( response.getData() );
					expect( decoded.sub ).toBe( 10 );
					expect( decoded.exp ).toBeGTE( dateAdd( "h", 1, decoded.iat ) );
				});
			});

			given( "invalid username and password", function(){
				then( "I will receive a 401 invalid credentials exception ", function(){
					var event = post(
						route = "/api/v1/login",
						params = {
							username = "invalid",
							password = "invalid"
						}
					);
					var response = event.getPrivateValue( "Response" );
					expect( response.getError() ).toBeTrue();
					expect( response.getStatusCode() ).toBe( 401 );
				});
			});

		});

		story( "I want to be able to logout from the system using my JWT token", function(){
			given( "a valid incoming jwt token and I issue a logout", function(){
				then( "my token should become invalidated and I will be logged out", function(){
					// Log in
					var token = jwtService.attempt( "Milkshake10", "test" );
					var payload = jwtService.decode( token );
					expect( cbauth.isLoggedIn() ).toBeTrue();

					// Now Logout
					var event = post(
						route = "/api/v1/logout",
						params = {
							"x-auth-token" : token
						}
					);

					var response = event.getPrivateValue( "Response" );
					expect( response.getError() ).toBeFalse( response.getMessages().toString() );
					expect( response.getStatusCode() ).toBe( 200 );
					expect( cbauth.isLoggedIn() ).toBeFalse();
				});
			});

			given( "an invalid incoming jwt token and I issue a logout", function(){
				then( "I should see an error message", function(){
					cbauth.logout();

					// Now Logout
					var event = post(
						route = "/api/v1/logout",
						params = {
							"x-auth-token" : "123"
						}
					);

					var response = event.getPrivateValue( "Response" );
					expect( response.getError() ).toBeTrue( response.getMessages().toString() );
					debug( response.getStatusCode( 500 ) );
				});
			});
		} );

	}

}
