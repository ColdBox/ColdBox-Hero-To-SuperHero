# Prerequisites

Please have the following software on your computer before the workshop. If everyone is downloading the software at once, it will slow everyone down, and we want to make the most of our time together.

## A Modern Computer

Please make sure you have a computer that is modern. No running windows 95, 7 or something funky from the year 2000.  Make sure you have plenty of FREE RAM (at least 4gb) and with a modern processor (at least an `i5`).  Most of the hiccups in trainings are when people do not meet the appropriate requirements in their own machines.

## Windows PRO

If you are in Windows you will need Windows PRO and not Windows Home in order for Docker Desktop to be installed.  We will be using Docker for our data services so you MUST be able to install and run docker containers.

> Ignore this if you are using WSL2 which is supported with docker as well.

## RESTFul Client

You will need a restful client for making requests. There are many, here are some:

* [Postman](https://www.getpostman.com/)
* [Insomnia](https://insomnia.rest/)
* [RestFox](https://github.com/flawiddsouza/Restfox)

## [Git](https://git-scm.com)

* https://git-scm.com

## Java JDK/JRE 21

JDK 21 is required for this workshop.  Make sure you have it installed.  You can download it from the following locations:

* https://adoptium.net/temurin/releases/

If you are on a Mac, just use homebrew:

```bash
brew install openjdk@21
```

If you are on *linux, use the following commands:

```bash
sudo apt update
sudo apt install -y openjdk-21-jdk
```

## CommandBox CLI (Version 6.\*)

* https://www.ortussolutions.com/products/commandbox#download

## [Docker](https://www.docker.com/community-edition#/download)

You will need Docker Desktop installed so we can run the database and be able to deploy our API as a docker container.   Once installed please issue the following commands to have our images ready in your machine:

```bash
docker pull mysql:8
docker pull ortussolutions/commandbox
```

That's it!

## CommandBox Modules

Once CommandBox is installed we will need to install some global modules. Start by opening a box shell by typing `box`.  Once in the shell you can type:

```bash
install commandbox-dotenv,commandbox-migrations,commandbox-cfformat,commandbox-cfconfig,commandbox-boxlang
```

## MySQL Server (8)

You need to have a running MySQL Server version 8 locally or use a provided Docker Compose file during the workshop.

If you don't have one already on your system, you can get started easily with
[Docker](https://www.docker.com/community-edition#/download) or download [MySQL](https://dev.mysql.com/downloads/mysql/) for your operating system.

## MySQL Client

You will want a SQL client to inspect and interact with your database.
You can use any client you would like. Here are a few we like ourselves:

* [Sequel Pro](https://sequelpro.com) (Mac, Free)
* [DBeaver](https://dbeaver.io) (Cross Platform, Free)
* [Heidi SQL](https://www.heidisql.com) (Windows, Free)
* [Table Plus](https://tableplus.com/) (Mac,Windows, Free)
* [Data Grip](https://www.jetbrains.com/datagrip/) (Cross Platform, Commercial / Free Trial)

## IDE

We recommend the following IDEs for development for this workshop

* [Microsoft VSCode](https://code.visualstudio.com/)

Make sure you have the following extensions installed. You can install them by going to the extensions tab and searching for them:

* [BoxLang](https://marketplace.visualstudio.com/items?itemName=ortus-solutions.vscode-boxlang)
* `vscode-coldbox`
* `vscode-testbox`
* `Docker`
* `Yaml`

## Useful Resources

* ColdBox API Docs: https://apidocs.ortussolutions.com/coldbox/current/index.html
* TestBox API Docs: https://apidocs.ortussolutions.com/testbox/current
* ColdBox Docs: https://coldbox.ortusbooks.com
* WireBox Docs: https://wirebox.ortusbooks.com
* TestBox Docs: https://testbox.ortusbooks.com
* Migrations: https://www.forgebox.io/view/commandbox-migrations
