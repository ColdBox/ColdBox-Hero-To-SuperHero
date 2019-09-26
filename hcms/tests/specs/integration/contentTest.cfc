component extends="tests.resources.BaseIntegrationSpec"{

	property name="jwtService" inject="provider:JwtService@cbsecurity";
	property name="cbauth" inject="provider:authenticationService@cbauth";

	/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "Content Services", function(){

			beforeEach(function( currentSpec ){
				// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
				// Need to login
				jwt = jwtService.attempt( "Milkshake10", "test" );
				getRequestContext().setValue( "x-auth-token", jwt );
			});

			story( "I want to be able to see content with different options", function(){

				it( "should display all content using the default options", function(){
					var event = get( route = "/api/v1/content" );
					var response = event.getPrivateValue( "Response" );
					expect( response.getError() ).toBeFalse( response.getMessages().toString() );
					expect( response.getData() ).toBeArray();
				});

				given( "a valid slug", function(){
					then( "I should be able to display the content object", function(){
						var testSlug = "Spoon-School-Staircase";
						var event = get( route = "/api/v1/content/#testSlug#" );
						var response = event.getPrivateValue( "Response" );

						debug( response.getMessages() );

						expect( response.getError() ).toBeFalse();
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

						expect( response.getError() ).toBeTrue();
						expect( response.getStatusCode() ).toBe( 404 );
					});
				});
			});

			story( "I want to be able to create new content objects", function(){
				given( "valid incoming data ", function(){
					then( "it should create a new content object", function(){
						var event = post(
							route = "/api/v1/content",
							params = {
								slug : "my-new-test-#createUUID()#",
								title : "I love BDD",
								body : "I love BDD sooooooooooo much!"
							}
						)
						// expectations go here.
						expect( false ).toBeTrue();
					});
				});
			});


			xit( "edit a content object", function(){
				var event = execute( event="content.update", renderResults=true );
				// expectations go here.
				expect( false ).toBeTrue();
			});

			xit( "delete a content object", function(){
				var event = execute( event="content.delete", renderResults=true );
				// expectations go here.
				expect( false ).toBeTrue();
			});
		} );

	}

}
