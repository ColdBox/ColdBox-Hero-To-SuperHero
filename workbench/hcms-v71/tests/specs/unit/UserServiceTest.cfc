component extends="coldbox.system.testing.BaseTestCase" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
	}

	function afterAll(){
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "UserService", function(){
			beforeEach( function( currentSpec ){
				setup();
				model = getInstance( "UserService" );
			} );

			it( "can be created", function(){
				expect( model ).toBeComponent();
			} );

		} );
	}

}
