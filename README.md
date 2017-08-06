MySQL SQL database server Docker image
======================================

[![Build Stauts](https://api.travis-ci.org/ravensys/container-mysql.svg?branch=master)](https://travis-ci.org/ravensys/container-mysql/)

This repository contains Dockerfiles and scripts for MySQL images based on CentOS.


Versions
--------

MySQL versions provided:

* [MySQL 5.6](5.6)
* [MySQL 5.7](5.7)

CentOS versions supported:

* CentOS 7


Installation
------------

* **CentOS 7 based image**

    This image is available on DockerHub. To download it run:
    
    ```
    $ docker pull ravensys/mysql:5.7-centos7
    ```

    To build a CentOS based MySQL image from source run:
    
    ```
    $ git clone --recursive https://github.com/ravensys/container-mysql
    $ cd container-mysql
    $ make build VERSION=5.7
    ```

For using other versions of MySQL just replace `5.7` value by particular version in commands above.


Usage
-----

For information about usage of Dockerfile for MySQL 5.6 see [usage documentation](5.6).

For information about usage of Dockerfile for MySQL 5.7 see [usage documentation](5.7).


Test
----

This repository also provides a test framework, which check basic functionality of MySQL image.

* **CentOS 7 based image**

    ```
    $ cd container-mysql
    $ make test VERSION=5.7
    ```
    
For using other versions of MySQL just replace `5.7` value by particular version in commands above.


Credits
-------

This project is derived from [`mysql-container`](https://github.com/sclorg/mysql-container) by 
[SoftwareCollections.org](https://www.softwarecollections.org).
