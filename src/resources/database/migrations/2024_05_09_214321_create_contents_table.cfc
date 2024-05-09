component {

    function up( schema, qb ) {
		schema.create( "content", function( table ) {
			table.increments( "id" );
			table.timestamps();
			table.string( "slug" ).unique();
			table.string( "title" );
			table.string( "body" );
			table.boolean( "isPublished" ).default( false );
			table.datetime( "publishedDate" ).nullable();
			table.unsignedInteger( "FK_userID" );
			table.foreignKey( "FK_userID" ).references( "id" ).onTable( "users" );
			table.index( [ "isPublished", "publishedDate" ], "idx_publishing" );
		} );
    }

    function down( schema, qb ) {
		schema.drop( "content" );
    }

}
