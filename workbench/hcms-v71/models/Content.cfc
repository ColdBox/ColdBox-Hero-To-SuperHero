/**
 * I am a Content object
 */
component
	accessors="true"
	transientCache="false"
	delegates = "Validatable@cbValidation,Population@cbDelegates"
{

	// inject the user service
	property name="userService" inject="UserService";
	property name="contentService" inject="ContentService";
	property name="qb" inject="provider:QueryBuilder@qb";

	// Properties
	property name="id" type="string";
	property name="slug" type="string";
	property name="title" type="string";
	property name="body" type="string";
	property name="isPublished" type="boolean";
	property name="publishedDate" type="date";
	property name="createdDate" type="date";
	property name="modifiedDate" type="date";
	property name="FK_userID" type="string";
	property name="user";


	// Validation Constraints
	this.constraints = {
		slug    	: { required : true, udf : ( value, target ) => {
			if( isNull( arguments.value ) ) return false;
            return qb.from( "content" ).where( "slug", arguments.value ).count() == 0;
		}},
		title       : { required : true },
		body       	: { required : true },
		FK_userID	: { required : true }
	};

	// Constraint Profiles
	this.constraintProfiles = {
		"update" : {}
	};

	// Population Control
	this.population = {
		include : [],
		exclude : [ "id" ]
	};

	// Mementifier
	this.memento = {
		// An array of the properties/relationships to include by default
		defaultIncludes = [
			"id",
			"slug",
			"title",
			"body",
			"isPublished",
			"publishedDate",
			"createdDate",
			"modifiedDate",
			"user.name",
			"user.email"
		 ],
		// An array of properties/relationships to exclude by default
		defaultExcludes = [
			"FK_userID",
			"user.id",
			"user.username",
			"user.roles",
			"user.permissions",
			"user.modifiedDate",
			"user.createdDate"
		],
		// An array of properties/relationships to NEVER include
		neverInclude = [],
		// A struct of defaults for properties/relationships if they are null
		defaults = {},
		// A struct of mapping functions for properties/relationships that can transform them
		mappers = {}
	};

	/**
	 * Constructor
	 */
	Content function init(){
		variables.createdDate 	= now();
		variables.modifiedDate 	= now();
		variables.isPublished 	= false;
		variables.FK_userID 	= "";
		return this;
	}

	/**
	 * Verify if the model has been loaded from the database
	 */
	function isLoaded(){
		return ( !isNull( variables.id ) && len( variables.id ) );
	}

	User function getUser(){
		return variables.userService.retrieveUserById( variables.FK_userId );
	}

	Content function setUser( required user ){

		if( isSimpleValue( arguments.user ) ){
			variables.FK_userId = arguments.user;
			return this;
		}

		if( arguments.user.isLoaded() ){
			variables.FK_userId = arguments.user.getId();
		}
		return this;
	}

	Content function save(){
		return variables.contentService.create( this );
	}


}
