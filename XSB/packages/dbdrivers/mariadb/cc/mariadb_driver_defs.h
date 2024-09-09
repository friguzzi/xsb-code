/* File: mariadb_driver.h
** Author: Saikat Mukherjee, Hui Wan
** Contact:   xsb-contact@cs.sunysb.edu
** 
** Copyright (C) The Research Foundation of SUNY, 2002-2008
** 
** Licensed under the Apache License, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**      http://www.apache.org/licenses/LICENSE-2.0
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
**
*/

/*
** This is the header file for the driver for connecting to a MySQL database.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mysql.h"
/*
  #include "mysql_com.h"
*/

#include "cinterf.h"
#include "driver_manager_defs.h"

/****** data structures for handles *****/

struct driverMariaDB_connectionInfo
{
	MYSQL* mariadb;
	char* handle;
};

struct driverMariaDB_queryInfo
{
	char* query;
	char* handle;
        int returnFields;
	MYSQL_RES* resultSet;
	struct driverMariaDB_connectionInfo* connection;
};

struct driverMariaDB_preparedresultset
{
	MYSQL_STMT* statement;
	struct xsb_queryHandle* handle;
	int returnFields;
	struct xsb_data** metaInfo;
        MYSQL_BIND* bindResult;
};


/****** function declarations *******/

DllExport int call_conv driverMariaDB_initialise();
int driverMariaDB_connect(struct xsb_connectionHandle* handle);
int driverMariaDB_disconnect(struct xsb_connectionHandle* handle);
struct xsb_data** driverMariaDB_query(struct xsb_queryHandle* handle);
int driverMariaDB_prepareStatement(struct xsb_queryHandle* handle);
struct xsb_data** driverMariaDB_execPrepareStmt(struct xsb_data** bindvalues, struct xsb_queryHandle* handle);
int driverMariaDB_closeStatement(struct xsb_queryHandle* handle);
char* driverMariaDB_errorMesg();
void driverMariaDB_freeResult();
DllExport int call_conv driverMariaDB_register();


DllExport extern int call_conv registerXSBDriver(char* dr, int num);
DllExport extern int call_conv registerXSBFunction(char* dr, int type, union functionPtrs* func);

#define NUMBER_OF_MYSQL_DRIVER_FUNCTIONS 8
