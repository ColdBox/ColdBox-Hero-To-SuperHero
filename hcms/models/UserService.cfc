/**
* I am a new Model Object
*/
component singleton accessors="true"{

	// Properties
	property name="bcrypt"      inject="@BCrypt";
	property name="auth"        inject="authenticationService@cbauth";
	property name="qb"          inject="provider:QueryBuilder@qb";
    property name="populator" 	inject="wirebox:populator";

	/**
	 * Constructor
	 */
	UserService function init(){
		return this;
	}

	User function new() provider="User";

	/**
	* create
	*/
	function create( required user ){
		var qResults = qb.from( "users" )
			.insert( values = {
				"name" 		= arguments.user.getName(),
				"email" 	= arguments.user.getEmail(),
				"username" 	= arguments.user.getUsername(),
				"password" 	= bcrypt.hashPassword( arguments.user.getPassword() )
			} );

		// populate the id
		arguments.user.setId( qResults.generatedKey );

		return arguments.user;
	}

	/**
	* isValidCredentials
	*/
	function isValidCredentials( required username, required password ){
		var oUser = retrieveUserByUsername( arguments.username );
		if( !oUser.isLoaded() ){ return false; }

		try{
			return bcrypt.checkPassword( arguments.password, oUser.getPassword() );
		} catch( any e ){
			return false;
		}
	}

	/**
	* retrieveUserByUsername
	*/
	function retrieveUserByUsername( required username ){
		return populator.populateFromStruct(
            new(),
            qb.from( "users" ).where( "username" , arguments.username ).first()
        );
	}

	/**
	* retrieveUserById
	*/
	function retrieveUserById( required id ){
		return populator.populateFromStruct(
            new(),
            qb.from( "users" ).where( "id" , arguments.id ).first()
        );
	}


}