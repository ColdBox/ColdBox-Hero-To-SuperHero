/**
 * This service provides user authentication, retrieval and much more.
 * Implements the CBSecurity IUserService: https://coldbox-security.ortusbooks.com/usage/authentication-services#iuserservice
 */
component accessors="true" singleton {

	/**
	 * --------------------------------------------------------------------------
	 * DI
	 * --------------------------------------------------------------------------
	 */

	property name="populator" inject="wirebox:populator";
	property name="bcrypt"      inject="@BCrypt";
	property name="qb"          inject="provider:QueryBuilder@qb";

	/**
	 * --------------------------------------------------------------------------
	 * Properties
	 * --------------------------------------------------------------------------
	 */

	/**
	 * Constructor
	 */
	function init(){
		return this;
	}

	/**
	 * Construct a new user object via WireBox Providers
	 */
	User function new() provider="User"{
	}

	/**
	 * Create a new user in the system
	 *
	 * @user The user to create
	 *
	 * @return The created user
	 */
	User function create( required user ){
		var qResults = qb.from( "users" )
			.insert( values = {
				"firstName"   : arguments.user.getFirstName(),
				"lastName"    : arguments.user.getLastName(),
				"username"    : arguments.user.getUsername(),
				"password" 	:  variables.bcrypt.hashPassword( arguments.user.getPassword() )
			} );

		// populate the id
		arguments.user.setId( qResults.result.generatedKey );

		return arguments.user;
	}

	/**
	 * Verify if the incoming username/password are valid credentials.
	 *
	 * @username The username
	 * @password The password
	 */
	boolean function isValidCredentials( required username, required password ){
		var oTarget = retrieveUserByUsername( arguments.username );
		if ( !oTarget.isLoaded() ) {
			return false;
		}

		// Check Password Here: Remember to use bcrypt
		try {
			return variables.bcrypt.checkPassword( arguments.password, oTarget.getPassword() );
		} catch ( any e ) {
			return false;
		}
	}

	/**
	 * Retrieve a user by username
	 *
	 * @return User that implements JWTSubject and/or IAuthUser
	 */
	function retrieveUserByUsername( required username ){
		return populator.populateFromStruct(
			new(),
			qb.from( "users" )
				.where( "username", arguments.username )
				.first()
		);
	}

	/**
	 * Retrieve a user by unique identifier
	 *
	 * @id The unique identifier
	 *
	 * @return User that implements JWTSubject and/or IAuthUser
	 */
	User function retrieveUserById( required id ){
		return populator.populateFromStruct(
			new(),
			qb.from( "users" )
				.where( "id", arguments.id )
				.first()
		);
	}

}
