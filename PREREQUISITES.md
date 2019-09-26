# Prerequisites

Please have the following software on your computer before the workshop. If everyone is downloading the software at once, it will slow everyone down, and we want to make the most of our time together.

## A Modern Computer

Please make sure you have a computer that is modern. No running windows 95, 7 or something funky from the year 2000.  Make sure you have plenty of FREE RAM (at least 4gb) and with a modern processor (at least an i5).  Most of the hiccups in trainings are when people do not meet the appropriate requirements in their own machines.  We will be running CFML engines and docker containers, so make sure you can run them.

## Windows PRO

If you are in Windows you will need Windows PRO and not Windows Home in order for Docker Desktop to be installed.  We will be using Docker for our data services so you MUST be able to install and run docker containers.

## [Postman](https://www.getpostman.com/)

We will be leveraging postman for RESTFul testing.

## [Git](https://git-scm.com)

* https://git-scm.com

## [Java](https://www.java.com/en/) (Version 8+)

This can be downloaded bundled with CommandBox if needed

* https://www.java.com/en/
* https://www.ortussolutions.com/products/commandbox

## [CommandBox CLI](https://www.ortussolutions.com/products/commandbox#download) (Version 4.\*)

* https://www.ortussolutions.com/products/commandbox#download

## [Docker](https://www.docker.com/community-edition#/download)

You will need Docker Desktop installed so we can run the database and be able to deploy our API as a docker container.   Once installed please issue the following commands to have our images ready in your machine:

```bash
docker pull mysql:5.7
docker pull ortussolutions/commandbox
```

That's it!

## CommandBox Modules

Once CommandBox is installed we will need to install some global modules. Start by opening a box shell by typing `box`.  Once in the shell you can type:

```bash
install commandbox-dotenv,commandbox-migrations,commandbox-cfformat,commandbox-cfconfig
```

## MySQL Server (5.7)

You need to have a running MySQL Server version 5.7 locally or use a provided Docker Compose file during the workshop.

If you don't have one already on your system, you can get started easily with
[Docker](https://www.docker.com/community-edition#/download) or download [MySQL](https://dev.mysql.com/downloads/mysql/) for your operating system.

> **Important** : Please make sure you have version 5.7 and not 5.8.  The JDBC drivers in Lucee and ACF have conflicting issues with MySQL version 5.8.

Make sure you download the image by issuing the following command: `docker pull mysql:5.7`

## MySQL Client

You will want a SQL client to inspect and interact with your database.
You can use any client you would like. Here are a few we like ourselves:

* [Sequel Pro](https://sequelpro.com) (Mac, Free)
* [Heidi SQL](https://www.heidisql.com) (Windows, Free)
* [Table Plus](https://tableplus.com/) (Mac,Windows, Free)
* [Data Grip](https://www.jetbrains.com/datagrip/) (Cross Platform, Commercial / Free Trial)

## IDE 

We recommend the following IDEs for development for this workshop

* [Microsoft VSCode](https://code.visualstudio.com/)
* [Sublime](https://www.sublimetext.com/)

If using VS Code, please install the following extensions:

* CFML - KamasamaK
* vscode-coldbox
* vscode-testbox
* Docker
* Yaml

If using Sublime, please install the following extensions:

* ColdBox Platform
* CFML
* CFMLDocPlugin
* Enhanced HTML and CFML
* DockerFile Syntax Highlighting
* Yaml

## Useful Resources

* ColdBox Api Docs: https://apidocs.ortussolutions.com/coldbox/5.6.2/index.html
* ColdBox Docs: https://coldbox.ortusbooks.com
* WireBox Docs: https://wirebox.ortusbooks.com
* TestBox Docs: https://testbox.ortusbooks.com
* TestBox Api Docs: https://apidocs.ortussolutions.com/testbox/3.1.0/index.html
* Migrations: https://www.forgebox.io/view/commandbox-migrations
