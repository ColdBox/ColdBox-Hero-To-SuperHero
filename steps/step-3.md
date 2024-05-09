# Step 3 - App Configuration

Open the `config/Coldbox.cfc` so we can start configuring our [application](../src/config/Coldbox.cfc):

## Development Settings

* Configure the `configure()` method for production
* Verify the `environment` structures
* Add the `development()` method settings

```js
function development(){
    coldbox.debugMode               = true;
    coldbox.customErrorTemplate     = "/coldbox/system/exceptions/Whoops.cfm";
    coldbox.handlersIndexAutoreload = true;
    coldbox.reinitPassword          = "";
    coldbox.handlerCaching          = false;
    coldbox.viewCaching             = false;
    coldbox.eventCaching            = false;
}
```

### Reiniting The Framework

Please note that every time we make changes to the `config` folder we will most likely need to reinitialize our application. ColdBox caches the contents of this file upon startup. So if you need the changes to take effect you must reinitialize the application.  But how you say?

* Hard Reset : issue a server reset command in CommandBox: `server restart`
* ColdBox CLI Reinit : issue a ColdBox reinit via CommandBox: `coldbox reinit`
* ColdBox URL Reinit : use the `http://localhost:42518?fwreinit=1` url action in your app

> You can secure the `fwreinit` by using the `reinitPassword` setting in your configuration. https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/coldbox#development-settings

What is cached?

* Configuration
* Singletons
* Handlers
* View/Event Caching


## Application Modules

We will install several modules to assist us with the development of our API

* `qb` - Fluent query builder for fancy queries (https://forgebox.io/view/qb)
* `bcrypt` - To enable encrypting of passwords (https://www.forgebox.io/view/BCrypt)
* `cbdebugger` - To help us debug our application (https://www.forgebox.io/view/cbdebugger), docs: https://cbdebugger.ortusbooks.com/

```bash
install qb,bcrypt,cbdebugger
```

Create the debugger configuration file:

```bash
touch config/modules/cbdebugger.cfc --open
```

Here is our config:

```java
component{

	function configure(){

		return {
			// This flag enables/disables the tracking of request data to our storage facilities
			// To disable all tracking, turn this master key off
			enabled          : true,
			// This setting controls if you will activate the debugger for visualizations ONLY
			// The debugger will still track requests even in non debug mode.
			debugMode        : controller.getSetting( name = "environment", defaultValue = "production" ) == "development",
			// The URL password to use to activate it on demand
			debugPassword    : "cb:null",
			// This flag enables/disables the end of request debugger panel docked to the bottem of the page.
			// If you disable i, then the only way to visualize the debugger is via the `/cbdebugger` endpoint
			requestPanelDock : true,
			// Request Tracker Options
			requestTracker   : {
				// Store the request profilers in heap memory or in cachebox, default is memory
				storage                      : "memory",
				// Which cache region to store the profilers in
				cacheName                    : "template",
				// Track all cbdebugger events, by default this is off, turn on, when actually profiling yourself :) How Meta!
				trackDebuggerEvents          : false,
				// Expand by default the tracker panel or not
				expanded                     : false,
				// Slow request threshold in milliseconds, if execution time is above it, we mark those transactions as red
				slowExecutionThreshold       : 1000,
				// How many tracking profilers to keep in stack
				maxProfilers                 : 50,
				// If enabled, the debugger will monitor the creation time of CFC objects via WireBox
				profileWireBoxObjectCreation : false,
				// Profile model objects annotated with the `profile` annotation
				profileObjects               : false,
				// If enabled, will trace the results of any methods that are being profiled
				traceObjectResults           : false,
				// Profile Custom or Core interception points
				profileInterceptions         : false,
				// By default all interception events are excluded, you must include what you want to profile
				includedInterceptions        : [],
				// Control the execution timers
				executionTimers              : {
					expanded           : true,
					// Slow transaction timers in milliseconds, if execution time of the timer is above it, we mark it
					slowTimerThreshold : 250
				},
				// Control the coldbox info reporting
				coldboxInfo : { expanded : false },
				// Control the http request reporting
				httpRequest : {
					expanded        : false,
					// If enabled, we will profile HTTP Body content, disabled by default as it contains lots of data
					profileHTTPBody : false
				}
			},
			// ColdBox Tracer Appender Messages
			tracers     : { enabled : true, expanded : false },
			// Request Collections Reporting
			collections : {
				// Enable tracking
				enabled      : false,
				// Expanded panel or not
				expanded     : false,
				// How many rows to dump for object collections
				maxQueryRows : 50,
				// How many levels to output on dumps for objects
				maxDumpTop   : 5
			},
			// CacheBox Reporting
			cachebox : { enabled : false, expanded : false },
			// Modules Reporting
			modules  : { enabled : false, expanded : false },
			// Quick and QB Reporting
			qb       : {
				enabled   : true,
				expanded  : true,
				// Log the binding parameters
				logParams : true
			},
			// cborm Reporting
			cborm : {
				enabled   : false,
				expanded  : false,
				// Log the binding parameters
				logParams : true
			},
			// Adobe ColdFusion SQL Collector
			acfSql   : { enabled : false, expanded : false, logParams : true },
			// Lucee SQL Collector
			luceeSQL : { enabled : false, expanded : false, logParams : true },
			// Async Manager Reporting
			async    : { enabled : true, expanded : false }
		};
	}
}
```

Now let's retinit the app for the changes to take effect

```bash
coldbox reinit
```

Now goto the http://127.0.0.1:42518/cbdebugger and you will see the debugger panel.  You can also use the `?fwreinit=1` to reinit the framework and see the debugger panel.  This will be essential when working with APIs.

## Datasource Configuration

Open `Application.cfc`  so we can add the global datasource we registered with the CFML Engine via  `.cfconfig.json`

```js
// App datasource
this.datasource = "cms";
```

Let's do the same with the tets application: `/tests/Application.cfc`

```js
// App datasource
this.datasource = "cms";
```


## Ensure Application

Try running the app again. If it runs, it works.  Or just issue a `testbox run`

Verify that we did not break our app:

* Let's use another cool command: `server open` to open the webroot
* But we can also use it to open any URI: `server open tests/runner.cfm`

Everything should be <span style="color: green">Green!</span>
