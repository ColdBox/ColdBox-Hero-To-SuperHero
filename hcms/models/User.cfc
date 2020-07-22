component accessors="true" {

	// DI
	property name="qb" inject="provider:QueryBuilder@qb";

	/**
	 * --------------------------------------------------------------------------
	 * Properties
	 * --------------------------------------------------------------------------
	 */

	// Properties
	property name="id"           type="string";
	property name="name"         type="string";
	property name="email"        type="string";
	property name="username"     type="string";
	property name="password"     type="string";
	property name="createdDate"  type="date";
    property name="modifiedDate" type="date";
	property name="permissions"  type="array";

	/**
	 * --------------------------------------------------------------------------
	 * Mementifier
	 * --------------------------------------------------------------------------
	 */
	this.memento = {
		defaultIncludes : [ "*" ],
		defaultExcludes : [],
		neverInclude    : [ "password" ]
	};

	/**
	 * --------------------------------------------------------------------------
	 * Validation
	 * --------------------------------------------------------------------------
	 */
	this.constraints = {
		name    : { required : true },
		email    : { required : true, type : "email" },
		username    : { required : true, udf : ( value, target ) => {
			if( isNull( arguments.value ) ) return false;
            return qb.from( "users" ).where( "username", arguments.value ).count() == 0;
        }},
        password    : { required : true }
	};

	/**
	 * Constructor
	 */
	function init() {
		variables.permissions = [];
		variables.createdDate = now();
		variables.modifiedDate = now();

		return this;
	}

	/**
	 * --------------------------------------------------------------------------
	 * Authentication/Authorization Methods
	 * --------------------------------------------------------------------------
	 */

	/**
	 * Check if a user is loaded from the db or not
	 */
	boolean function isLoaded() {
		return ( !isNull( variables.id ) && len( variables.id ) );
	}

	/**
	 * Verify if the user has one or more of the passed in permissions
	 *
	 * @permission One or a list of permissions to check for access
	 *
	 */
	boolean function hasPermission( required permission ) {
		// If no permissions, then it a default value of true comes in
		if ( isBoolean( arguments.permission ) && arguments.permission ) {
			return true;
		}

		if ( isSimpleValue( arguments.permission ) ) {
			arguments.permission = listToArray( arguments.permission );
		}

		return arguments.permission
			.filter( function( item ) {
				return ( variables.permissions.findNoCase( item ) );
			} )
			.len();
	}

	/**
	 * --------------------------------------------------------------------------
	 * IJwtSubject Methods
	 * --------------------------------------------------------------------------
	 */

	/**
	 * A struct of custom claims to add to the JWT token
	 */
	struct function getJwtCustomClaims() {
		return {};
	}

	/**
	 * This function returns an array of all the scopes that should be attached to the JWT token that will be used for authorization.
	 */
	array function getJwtScopes() {
		return [];
	}

}
