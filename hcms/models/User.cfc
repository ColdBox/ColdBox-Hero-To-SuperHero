/**
* I am a new Model Object
*/
component accessors="true"{

	// DI
	property name="auth" inject="authenticationService@cbauth";
	property name="qb" inject="provider:QueryBuilder@qb";

	// Properties
	property name="id"           type="string";
	property name="name"         type="string";
	property name="email"        type="string";
	property name="username"     type="string";
	property name="password"     type="string";
	property name="createdDate"  type="date";
	property name="modifiedDate" type="date";

	this.constraints = {
        name        : { required : true },
        email       : { required : true, type : "email" },
        username    : { required : true, udf : ( value, target ) => {
            return qb.from( "users" ).where( "username", arguments.value ).count() == 0;
        }},
        password    : { required : true }
    };

    this.memento = {
		defaultIncludes = [ "*" ],
		neverInclude = [ "password" ]
	};

	/**
	 * Constructor
	 */
	User function init(){

		variables.createdDate = now();
		variables.modifiedDate = now();

		return this;
	}

	boolean function isLoaded(){
		return ( !isNull( variables.id ) && len( variables.id ) );
	}

	/**
     * A struct of custom claims to add to the JWT token
     */
    struct function getJwtCustomClaims(){
		return {};
	}

    /**
     * This function returns an array of all the scopes that should be attached to the JWT token that will be used for authorization.
     */
	array function getJwtScopes(){
		return [];
	}

    /**
     * Verify if the user has one or more of the passed in permissions
     *
     * @permission One or a list of permissions to check for access
     *
     */
    boolean function hasPermission( required permission ){
		return true;
	}

    /**
     * Shortcut to verify it the user is logged in or not.
     */
    boolean function isLoggedIn(){
		return auth.isLoggedIn();
	}

}