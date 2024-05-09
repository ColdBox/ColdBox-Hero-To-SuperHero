/**
 * I am a Content Object
 */
component accessors="true"{

	// DI
	property name="userService" inject="UserService";

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


	// Validation Constraints
	this.constraints = {
		slug    	: {
			required : true,
			udf : ( value, target ) => {
				if( isNull( arguments.value ) ) return false;
            	return qb.from( "content" ).where( "slug", arguments.value ).count() == 0;
			}
		},
		title       : { required : true },
		body       	: { required : true },
		FK_userID	: { required : true },
		isPublished : { type : "boolean" }
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
		defaultIncludes = [
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
		defaultExcludes = [
			"FK_userID",
			"user.id",
			"user.username",
			"user.modifiedDate",
			"user.createdDate"
		]
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
		if( user.isLoaded() ){
			variables.FK_userId = arguments.user.getId();
		}
		return this;
	}

}
