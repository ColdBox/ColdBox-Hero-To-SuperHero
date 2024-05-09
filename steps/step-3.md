# Step 3 - Setup the TestHarness and Base Spec

Let's create a base spec class all of our integration tests will inherit from.  Place it under `tests/resources/BaseIntegrationSpec.cfc`.

```js
/**
 * Base test bundle for our application
 *
 * @see https://coldbox.ortusbooks.com/testing/testing-coldbox-applications/integration-testing
 */
component extends="coldbox.system.testing.BaseTestCase" autowire{

     /**
	 * --------------------------------------------------------------------------
	 * Dependency Injections
	 * --------------------------------------------------------------------------
	 */

    /**
	 * --------------------------------------------------------------------------
	 * Integration testing controls
	 * --------------------------------------------------------------------------
     * - We want the ColdBox virtual application to load once per request and get destroyed at the end of the request.
	 */
    this.loadColdBox    = true;
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
	}

	function afterAll(){
		super.afterAll();
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
                arguments.spec.body( argumentCollection = arguments );
            } catch ( any e ){
                rethrow;
            } finally {
                transaction action="rollback";
            }
        }
    }

}
```

Go update the specs you have by adding the `extends="tests.resources.BaseIntegrationSpec"` and let's run the tests again and make sure they pass!
