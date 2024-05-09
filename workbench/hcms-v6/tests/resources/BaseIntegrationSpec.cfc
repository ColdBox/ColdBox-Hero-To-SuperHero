component extends="coldbox.system.testing.BaseTestCase" appMapping="/root"{

    // Load on first test
    this.loadColdBox    = true;
    // Never unload until the request dies
	this.unloadColdBox  = false;

	/**
	 * --------------------------------------------------------------------------
	 * Fixture Data
	 * --------------------------------------------------------------------------
	 * Here is the global fixture data you can use
	 */

	/*********************************** LIFE CYCLE Methods ***********************************/

    /**
     * Run Before all tests
     */
    function beforeAll() {
        super.beforeAll();
        // Wire up the test object with dependencies
		application.wirebox.autowire( this );

		// Add Custom Matchers
		addMatchers( {
			toHaveStatus : ( expectation, args = {} ) => {
				// handle both positional and named arguments
				param args.statusCode = "";
				if ( structKeyExists( args, 1 ) ) {
					args.statusCode = args[ 1 ];
				}
				param args.message = "";
				if ( structKeyExists( args, 2 ) ) {
					args.message = args[ 2 ];
				}
				if ( !len( args.statusCode ) ) {
					expectation.message = "No status code provided.";
					return false;
				}
				var statusCode = expectation.actual.getStatusCode();
				if ( statusCode != args.statusCode ) {
					expectation.message = "#args.message#. Received incorrect status code. Expected [#args.statusCode#]. Received [#statusCode#].";
					debug( expectation.actual.getMemento() );
					return false;
				}
				return true;
			},
			// Verifies invalid cbValidation data
			toHaveInvalidData : ( expectation, args = {} ) => {
				param args.field = "";
				if ( structKeyExists( args, 1 ) ) {
					args.field = args[ 1 ];
				}
				param args.error = "";
				if ( structKeyExists( args, 2 ) ) {
					args.error = args[ 2 ];
				}
				param args.message = "";
				if ( structKeyExists( args, 3 ) ) {
					args.message = args[ 3 ];
				}

				// If !400 then there is no invalid data
				if ( expectation.actual.getStatusCode() != 400 ) {
					expectation.message = "#args.message#. Received incorrect status code. Expected [400]. Received [#expectation.actual.getStatusCode()#].";
					debug( expectation.actual.getMemento() );
					return false;
				}
				// If no field passed, we just check that invalid data was found
				if ( !len( args.field ) ) {
					if ( expectation.actual.getData().isEmpty() ) {
						expectation.message = "#args.message#. Received incorrect status code. Expected [400]. Received [#expectation.actual.getStatusCode()#].";
						debug( expectation.actual.getMemento() );
						return false;
					}
					return true;
				}
				// We have a field to check and it has data
				if (
					!structKeyExists(
						expectation.actual.getData(),
						args.field
					) || expectation.actual.getData()[ args.field ].isEmpty()
				) {
					expectation.message = "#args.message#. The requested field [#args.field#] does not have any invalid data.";
					debug( expectation.actual.getMemento() );
					return false;
				}
				// Do we have any error messages to check?
				if ( len( args.error ) ) {
					try {
						expect(
							expectation.actual.getData()[ args.field ]
								.map( ( item ) => item.message )
								.toList()
						).toInclude( args.error );
					} catch ( any e ) {
						debug( expectation.actual.getMemento() );
						rethrow;
					}
				}

				// We checked and it's all good!
				return true;
			}
		} );
	}

	function afterAll(){
		super.afterAll();
	}

	function reset(){
		application.cbController.getLoaderService().processShutdown();
		structDelete( application, "wirebox" );
		structDelete( application, "cbController" );
	}

    /**
     * This function is tagged as an around each handler.  All the integration tests we build
     * will be automatically rolled backed. No database corruption
     *
     * @aroundEach
     */
    function wrapInTransaction( spec ) {
        transaction action="begin" {
            try {
                arguments.spec.body();
            } catch ( any e ){
                rethrow;
            } finally {
                transaction action="rollback";
            }
        }
    }

}