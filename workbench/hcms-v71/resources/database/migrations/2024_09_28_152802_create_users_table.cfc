component {

    function up( schema, qb ) {
        schema.create( "users", function( table ) {
            table.increments( "id" )
            table.string( "firstName" )
            table.string( "lastName" )
            table.string( "username" ).unique()
            table.string( "password" )
            table.timestamps()
        } );
    }

    function down( schema, qb ) {
		schema.drop( "users" )
    }

}
