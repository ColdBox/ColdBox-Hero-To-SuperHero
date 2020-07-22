component extends="tests.resources.BaseIntegrationSpec" {

	property name="jwtService" inject="provider:JwtService@cbsecurity";
	property name="cbauth"     inject="provider:authenticationService@cbauth";

	/*********************************** BDD SUITES ***********************************/

	function run() {
		describe( "Content Services: In order to interact with content in the CMS you must be authenticated", function() {
			beforeEach( function( currentSpec ) {
				// Setup as a new ColdBox request for this suite, VERY IMPORTANT. ELSE EVERYTHING LOOKS LIKE THE SAME REQUEST.
				setup();
				// Need to login
				jwt = jwtService.attempt( "Milkshake10", "test" );
				getRequestContext().setValue( "x-auth-token", jwt );
			} );

			story( "I want to be able to see content with different options", function() {
				it( "should display all content using the default options", function() {
					var event    = get( route = "/api/v1/content" );
					var response = event.getPrivateValue( "Response" );
					expect( response ).toHaveStatus( 200 );
					expect( response.getData() ).toBeArray();
				} );
			} );

			story( "I want to see a single content object via a nice slug", function() {
				given( "a valid slug", function() {
					then( "I should be able to display the content object", function() {
						var testSlug = "Spoon-School-Staircase";
						var event    = get( route = "/api/v1/content/#testSlug#" );
						var response = event.getPrivateValue( "Response" );

						debug( response.getMessages() );

						expect( response ).toHaveStatus( 200 );
						expect( response.getData() ).toBeStruct();
						expect( response.getData().slug ).toBe( testSlug );
					} );
				} );

				given( "an invalid slug", function() {
					then( "then we should get a 404", function() {
						var testSlug = "invalid-bogus-object";
						var event    = get( route = "/api/v1/content/#testSlug#" );
						var response = event.getPrivateValue( "Response" );

						debug( response.getMessages() );

						expect( response ).toHaveStatus( 404 );
					} );
				} );
			} );

			story( "I want to be able to create new content objects", function() {
				given( "valid incoming data", function() {
					then( "it should create a new content object", function() {
						var event = post(
							route  = "/api/v1/content",
							params = {
								slug          : "my-new-test-#createUUID()#",
								title         : "I love BDD",
								body          : "I love BDD sooooooooooo much!",
								isPublished   : true,
								publishedDate : now()
							}
						)

						// expectations go here.
						var response = event.getPrivateValue( "Response" );

						debug( response.getData() );

						expect( response ).toHaveStatus( 200 );
						expect( response.getData().title ).toBe( "I love BDD" );
						expect( response.getData().id ).notToBeEmpty();
					} );
				} );

				given( "invalid data", function() {
					then( "it should throw a validation error", function() {
						var event = post(
							route  = "/api/v1/content",
							params = {
								body          : "I love BDD sooooooooooo much!",
								isPublished   : true,
								publishedDate : now()
							}
						)

						// expectations go here.
						var response = event.getPrivateValue( "Response" );

						expect( response ).toHaveStatus( 400 );
						expect( response ).toHaveInvalidData( "slug", "is required" );
					} );
				} );
			} );

			story( "I want to be able to update content objects", function() {
				given( "valid incoming data", function() {
					then( "it should update the content object", function() {
						var event = put(
							route  = "/api/v1/content/Record-Slave-Crystal",
							params = {
								title       : "I just changed you!",
								body        : "I love BDD sooooooooooo much!",
								isPublished : false
							}
						)

						// expectations go here.
						var response = event.getPrivateValue( "Response" );

						debug( response.getData() );

						expect( response ).toHaveStatus( 200 );
						expect( response.getData().title ).toBe( "I just changed you!" );
						expect( response.getData().id ).notToBeEmpty();
					} );
				} );

				given( "an invalid slug", function() {
					then( "it should throw a validation error", function() {
						var event = put(
							route  = "/api/v1/content/bogus",
							params = {
								body          : "I love BDD sooooooooooo much!",
								isPublished   : true,
								publishedDate : now()
							}
						)

						// expectations go here.
						var response = event.getPrivateValue( "Response" );

						expect( response ).toHaveStatus( 404 );
					} );
				} );
			} );

			story( "I want to be able to remove content objects", function() {
				given( "a valid incoming slug", function() {
					then( "it should remove content object", function() {
						var event = DELETE( route = "/api/v1/content/Record-Slave-Crystal" );

						// expectations go here.
						var response = event.getPrivateValue( "Response" );

						debug( response.getData() );

						expect( response ).toHaveStatus( 200 );
						expect( response.getMessages().toString() ).toInclude( "Content deleted" );
					} );
				} );

				given( "an invalid slug", function() {
					then( "it should throw a validation error", function() {
						var event = delete( route = "/api/v1/content/bogus" );

						// expectations go here.
						var response = event.getPrivateValue( "Response" );

						expect( response ).toHaveStatus( 404 );
					} );
				} );
			} );
		} );
	}

}
