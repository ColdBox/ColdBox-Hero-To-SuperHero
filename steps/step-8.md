# Step 8 - API Tooling

## Invalid Routes

Ok, so what would happen if we try to execute `/api/v1/bogus` in the browser?  Go and try it!

You will see that the browser blows up with a nasty invalid event. actually, ANY route we try to execute in the `v1` api will fail like this and this is not nice.  We want uniformity, so let's add a catch all route that issues the Rest Handler's `onInvalidRoute()` method.

Open the `v1` router and add the invalid routes catch all before the default route and actually remove the default route as we won't be using it.

```java
// Invalid Routes
route( "/:anything", "echo.onInvalidRoute" );
//route( "/:handler/:action" ).end();
```

Issue a nice `coldbox reinit` and hit the route again or any invalid route and you should see a nice API return 404 message. Now, this is great, but we lost something? Anybody can guess?

> We lost all of our convention based routing which was below it.  This means, that we must register all the routes we want.

## Swagger

Ok, before we go any further building stuff out, let's go over the weird documentation in our handlers.  Go open one and try to decipher it? We are using cbswagger directives so we can document our API.  Go to http://127.0.0.1:42518/cbswagger and see the json created for you.  Copy it and go to https://editor.swagger.io/ and paste it in.

WOW! Our API is fully documented! What magic unicorn is this!

* https://www.forgebox.io/view/cbswagger
* https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md

### Customize It

Open your [`config/modules/cbswagger.cfc`](../src/config/modules/cbswagger.cfc).  Let's update it a bit to match what we are building:

```js
cbswagger : {
	// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
	"routes"        : [ "api" ],
	// Any routes to exclude: EXCLUDE OUR INVALID ROUTES
	"excludeRoutes" : [ "api/v1/:anything/" ],
	// The default output format: json or yml
	"defaultFormat" : "json",
	// A convention route, relative to your app root, where request/response samples are stored ( e.g. resources/apidocs/responses/[module].[handler].[action].[HTTP Status Code].json )
	"samplesPath"   : "resources/apidocs",
	// Information about your API
	"info"          : {
		// A title for your API
		"title"       : "Hero to SuperHero Headless CMS",
		// A description of your API
		"description" : "A nice hmvc headless CMS",
		// The contact email address
		"contact"     : {
			"name"  : "API Support",
			"url"   : "https://www.swagger.io/support",
			"email" : "info@ortussolutions.com"
		},
		// A url to the License of your API
		"license" : {
			"name" : "Apache 2.0",
			"url"  : "https://www.apache.org/licenses/LICENSE-2.0.html"
		},
		// The version of your API
		"version" : "1.0.0"
	},
	// Tags
	"tags"         : [ ],
	// https://swagger.io/specification/#externalDocumentationObject
	"externalDocs" : {
		"description" : "Find more info here",
		"url"         : "https://blog.readme.io/an-example-filled-guide-to-swagger-3-2/"
	},
	// https://swagger.io/specification/#serverObject
	"servers" : [
		{
			"url"         : "https://mysite.com/v1",
			"description" : "The main production server"
		},
		{
			"url"         : "http://127.0.0.1:42518",
			"description" : "The dev server"
		}
	],
	// An element to hold various schemas for the specification.
	// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#componentsObject
	"components" : {
		// Define your security schemes here
		// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securitySchemeObject
		"securitySchemes" : {
			"ApiKeyAuth" : {
				"type"        : "apiKey",
				"description" : "User your JWT as an Api Key for security",
				"name"        : "x-api-key",
				"in"          : "header"
			},
			"bearerAuth" : {
				"type"         : "http",
				"scheme"       : "bearer",
				"bearerFormat" : "JWT"
			}
		}
	}

	// A default declaration of Security Requirement Objects to be used across the API.
	// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securityRequirementObject
	// Only one of these requirements needs to be satisfied to authorize a request.
	// Individual operations may set their own requirements with `@security`
	// "security" : [
	//	{ "APIKey" : [] },
	//	{ "UserSecurity" : [] }
	// ]
},
```

### Resources

You can also find all the resources we generated previously from our app template in the `resources/apidocs` folder. You will find here global schemas, and our routing by convention.  Let's explore them and update them accordingly since our model changed.

#### Extra Credit

* Update all resources to match our new API structure.

Regenerate the swagger doc and we have our internal routing removed! Voila!


### PostMan / Insomnia Automation

Let's do one more mystical trick.  Copy the swagger json and open Postman or Insomnia. Look for the import and import our cbwagger.

WOW!  We know have imported all of our API into Postman / Insomnia for testing and even more sweet documentation!
