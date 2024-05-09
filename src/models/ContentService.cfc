/**
 * Manage content in the system
 */
component singleton {

	// DI
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
	 * List all content
     *
	 * @orderBy The field to order by default is publishedDate
	 * @orderType The order type (asc or desc) default is asc
	 *
	 * @return array
	 */
	array function list( orderBy="publishedDate", orderType="asc" ){
		return qb
			.from( "content" )
			.orderBy( arguments.orderBy, arguments.orderType )
			.get()
			.map( ( content ) => {
				return populator.populateFromStruct(
					target : new(),
					memento : content,
					ignoreTargetLists : true
				);
			} );
	}

	/**
	 * Get a content by id
	 *
	 * @id The id of the content
	 *
	 * @return A persisted Content or an empty one
	 */
	function get( required id ){
		return populator.populateFromStruct(
            target : new(),
            memento : qb.from( "content" ).where( "id" , arguments.id ).first(),
			ignoreTargetLists : true
        );
	}

	/**
	 * Find by slug
	 *
	 * @slug The slug of the content
	 *
	 * @return A persisted Content or an empty one
	 */
	function findBySlug( required slug ){
		return populator.populateFromStruct(
            target : new(),
            memento : qb.from( "content" ).where( "slug" , arguments.slug ).first(),
			ignoreTargetLists : true
        );
	}

}
