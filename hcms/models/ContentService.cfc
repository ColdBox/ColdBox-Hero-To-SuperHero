/**
* I am a new Model Object
*/
component singleton accessors="true"{

	// Properties
	property name="populator" 	inject="wirebox:populator";
	property name="qb"          inject="provider:QueryBuilder@qb";

	/**
	 * Constructor
	 */
	ContentService function init(){
		return this;
	}

	Content function new() provider="Content";

	/**
	* list
	*/
	array function list( orderBy="publishedDate", orderType="asc" ){
		return qb
			.from( "content" )
			.orderBy( arguments.orderBy, arguments.orderType )
			.get()
			.map( ( content ) => {
				return populator.populateFromStruct(
					new(),
					content
				);
			} );
	}

	/**
	* create
	*/
	function create( required content ){
		var qResults = qb.from( "content" )
			.insert( values = {
				"slug" 			= arguments.content.getSlug(),
				"title" 		= arguments.content.getTitle(),
				"body" 			= arguments.content.getBody(),
				"isPublished" 	= { value : arguments.content.getIsPublished(), cfsqltype : "tinyint" },
				"publishedDate" = { value : arguments.content.getPublishedDate(), cfsqltype : "timestamp", null : !len( arguments.content.getPublishedDate() ) },
				"createdDate" 	= { value : now(), cfsqltype : "timestamp" },
				"modifiedDate" 	= { value : now(), cfsqltype : "timestamp" },
				"FK_userId"		= arguments.content.getUser().getId()
			} );

		// populate the id
		arguments.content.setId( qResults.result.generatedKey );

		return arguments.content;
	}

	/**
	* update
	*/
	function update( required content ){
		var qResults = qb.from( "content" )
			.whereId( arguments.content.getId() )
			.update( {
				"slug" 			= arguments.content.getSlug(),
				"title" 		= arguments.content.getTitle(),
				"body" 			= arguments.content.getBody(),
				"isPublished" 	= { value : arguments.content.getIsPublished(), cfsqltype : "tinyint" },
				"publishedDate" = { value : arguments.content.getPublishedDate(), cfsqltype : "timestamp" },
				"modifiedDate" 	= { value : now(), cfsqltype : "timestamp" },
				"FK_userId"		= arguments.content.getUser().getId()
			} );

		return arguments.content;
	}

	/**
	 * delete
	 */
	function delete( required content ){
		var qResults = qb.from( "content" )
			.whereId( arguments.content.getId() )
			.delete();

		arguments.content.setId( "" );

		return arguments.content;
	}

	/**
	* get
	*/
	function get( required id ){
		return populator.populateFromStruct(
            new(),
            qb.from( "content" ).where( "id" , arguments.id ).first()
        );
	}

	/**
	* Find by slug
	*/
	function findBySlug( required slug ){
		return populator.populateFromStruct(
            new(),
            qb.from( "content" ).where( "slug" , arguments.slug ).first()
        );
	}


}