# ColdBox From Hero to SuperHero

In this workshop you will be introduced to the latest version of the most popular CFML MVC framework; ColdBox 7. We will go over the basics of installation, templating and configuration to the most advanced features like HMVC development with modules, RESTFul APIs, interception points, integration testing and much more.

## Prerequisites

- Latest CommandBox CLI
- A local database server (MySql 8 is recommended)
  - Or you can use the provided Docker Compose file
- Basic to Intermediate ColdFusion (CFML) Knowledge
- Basic ColdBox Experience

## Software Versions

This course at this time is using the following dependencies:

- ColdBox 7.x
- CBSecurity 3.x
- CBDebugger 4.x
- CommandBox Migrations 4.x

**There could be the case that some of the steps fail if you are using future versions of these modules.  Please update accordingly or look for the specific updated version of this course as a branch.**

## Course Outline

This course will focus on building a headless CMS based on different concepts and tool methodologies. We will use ColdBox features, including Behavior Driven Development (BDD) testing and leveraging several ForgeBox modules.

> (All commands assume we are in the `box` shell unless stated otherwise.)

### 1. Course Introduction

- Introductions
  - Software Pre-Requisites
  - Course Expectations
  - How many have used ColdBox/MVC before?
  - How many have used BDD/TDD approaches before?

### 2. App Setup

- Run our database
- Scaffold our application
- Configure the Test Harness
- Run our initial tests

Steps:

- [Start](steps/step-2.md)

### 3. App Configuration

What we will do:

- Prepare app for development
- Install more modules
- Datasource configurations

Steps:

- [Start](steps/step-3.md)

### 4. Setup the Test Harness and Base Spec

What we will do:

- Create a Base Integration Spec
- Update all our specs to use it
- Verify our tests are running

Steps:

- [Start](steps/step-4.md)

### 5. Security Configuration

- Configure the firewall, logging and visualizer
- Configure the JWT secret
- Go through the security visualizer

Steps:

- [Start](steps/step-5.md)

### 6. Registration

- Go over our acceptance story
- Review and update our `User` object
- Create our migrations
- Update our `User` service to make it real
- Update our tests

Steps:

- [Start](steps/step-6.md)

### 7. Authentication

- Acceptance stories
- BDD
- Routing
- Event Handler
- User Service
- Seed Data
- Tests

Steps:

- [Start](steps/step-7.md)

### 8. API Tooling

- Listen to invalid routes
- Prepare for API documentation via OpenAPI
- Generate the OpenAPI documentation
- Explore the generated documentation
- Import the documentation into Postman or Insomnia

Steps:

- [Start](steps/step-8.md)

### 9. Listing Content

What we will do:

- Create a `Content` object
- Create a `ContentService`
- Create the migration and seeders
- Create the handler
- Test it out

Steps:

- [Start](steps/step-9.md)

### 10. Creating Content

What we will do:

- BDD for creating content
- Creating the action
- Creating the service method
- Testing

Steps:

- [Start](steps/step-10.md)

### 11. Updating Content

What we will do:

- BDD for updating content
- Creating the action
- Creating the service method
- Testing

Steps:

- [Start](steps/step-11.md)

### 14. Extra Credit

- Ability to see global and user rants in JSON
- Don't let a user poop and bump the same rant
- When you bump or poop from the user profile page - take the user back to that page, not the main rant page. Ie - return them to where they started
- Convert the bump and poop to AJAX calls
- CSRF tokens for login, register, and new rant
- Move `queryExecute` to `qb`

Other Ideas:

- Environments in ColdBox.cfc
- Domain Names in CommandBox
