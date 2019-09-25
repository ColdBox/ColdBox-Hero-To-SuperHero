component extends="tests.resources.BaseIntegrationSpec"{

	property name="qb" inject="provider:QueryBuilder@qb";

	/*********************************** BDD SUITES ***********************************/

	function run(){

		story( "I want to be able to register users in my system and assign them a JWT token upon registration", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
			});

			given( "valid registration data and the username is available", function(){
				then( "I will be able to register my new user and get an access token", function(){
					// Test user doesn't exist
					expect(
						qb.from( "users" )
							.where( "username", "testadmin" )
							.count()
					).toBe( 0 );

					var event = post( "/api/v1/registration", {
						"name"					= "Your Name",
						"email"                	= "testadmin@ortussolutions.com",
						"username"             	= "testadmin",
						"password"             	= "testadmin"
					} );
					var response = event.getPrivateValue( "response" );

					expect( response.getError() ).toBeFalse();
					expect( response.getData().token ).notToBeEmpty();
					expect( response.getData().user.id ).toBeNumeric();
					expect( response.getData().user.name ).toBe( "Your Name" );

					// data = { user:struct, token:jwt token }

				});
			});

		});

	}

}