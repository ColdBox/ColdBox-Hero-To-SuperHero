/**
 * See https://forgebox.io/view/mockdatacfc
 */
component {

    function run( qb, mockdata ) {
		var aContent = mockdata.mock(
			$num = 25,
			"id": "autoincrement",
			"slug" : ( index ) => { return "content-slug-" & index; },
			"title" : "sentence",
			"body" : "baconlorem",
			"isPublished" : "oneof:1:0",
			"publishedDate" = "datetime",
			"FK_userID" = "num:25"
		).map( function( row ) {
			row.publishedDate = {
				value : dateTimeFormat( row.publishedDate, "iso8601" ),
				cfsqltype : "timestamp"
			}
			return row;
		} );

		//writedump( var: aContent, output : "console" );

		qb.table( "content" ).insert( aContent );
    }

}
