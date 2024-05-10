/**
 * A user in the system.
 *
 * This user is based off the Auth User included in cbsecurity, which implements already several interfaces and properties.
 * - https://coldbox-security.ortusbooks.com/usage/authentication-services#iauthuser
 * - https://coldbox-security.ortusbooks.com/jwt/jwt-services#jwt-subject-interface
 *
 * It also leverages several delegates for Validation, Population, Authentication, Authorization and JWT Subject.
 */
component
	accessors     ="true"
	extends       ="cbsecurity.models.auth.User"
	transientCache="false"
	delegates     ="
		Validatable@cbvalidation,
		Population@cbDelegates,
		Auth@cbSecurity,
		Authorizable@cbSecurity,
		JwtSubject@cbSecurity
	"
{

	// DI
	property name="qb" inject="provider:QueryBuilder@qb";

	// Properties
	property name="createdDate"  type="date";
	property name="modifiedDate" type="date";

	/**
	 * Constructor
	 */
	function init(){
		super.init();

		// Update constraints
		this.constraints.username = {
			required : true,
			udf : ( value, target ) => {
				if( isNull( arguments.value ) ) return false;
				return qb.from( "users" ).where( "username", arguments.value ).count() == 0;
			}
		};

		// Change default includes to just *
		this.memento.defaultIncludes = [ "*" ];

		// Initialize dates
		variables.createdDate = now();
		variables.modifiedDate = now();

		return this;
	}

}
