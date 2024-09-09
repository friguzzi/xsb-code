/* File: mariadb_driver.c
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
** This is the driver for connecting to a MariaDB database.
** This is invoked from the middle_layer module in emu.
*/

#include "../../cc/nodeprecate.h"

#include "xsb_config.h"

#ifdef WIN_NT
#include <windows.h>
#endif

#ifdef WIN_NT
#define XSB_DLL
#endif

#include "mariadb_driver_defs.h"

static void driverMariaDB_error(MYSQL* mariadb);
static int driverMariaDB_getXSBType(MYSQL_FIELD* field);
static struct xsb_data** driverMariaDB_getNextRow(struct driverMariaDB_queryInfo* query);
static struct xsb_data** driverMariaDB_prepNextRow(struct driverMariaDB_preparedresultset* rs);

void freeQueryInfo(struct driverMariaDB_queryInfo* query);
void freeConnection(struct driverMariaDB_connectionInfo* connection);
//void freeResult(struct xsb_data** result, int numOfElements);
void freeResultset(struct driverMariaDB_preparedresultset* rs);
void freeBind(MYSQL_BIND* bind, int num);

struct driverMariaDB_connectionInfo* mariadbHandles[MAX_CONNECTIONS];
struct driverMariaDB_queryInfo* mariadbQueries[MAX_QUERIES];
struct driverMariaDB_preparedresultset* prepQueries[MAX_QUERIES];
int numHandles, numQueries;
int numPrepQueries;

static const char* errorMesg;


DllExport int call_conv driverMariaDB_initialise()
{
  numHandles = 0;
  numQueries = 0;
  numPrepQueries = 0;
  errorMesg = NULL;

  return TRUE;
}


int driverMariaDB_connect(struct xsb_connectionHandle* handle)
{
  struct driverMariaDB_connectionInfo* mariadbHandle;
  MYSQL *mariadb = mysql_init( NULL );
  if ( mariadb == NULL ) {
    errorMesg = "mysql_init() failed\n";	
    return FAILURE;
  }
	
  if (!mysql_real_connect(mariadb, handle->server, handle->user,
                          handle->password, handle->database, 0, NULL, 0)) {
    driverMariaDB_error(mariadb);
    mysql_close(mariadb);
    mariadb = NULL;
    return FAILURE; 
    }
	
  mariadbHandle = (struct driverMariaDB_connectionInfo *)malloc(sizeof(struct driverMariaDB_connectionInfo));
  mariadbHandle->handle =
    (char *)malloc((strlen(handle->handle) + 1) * sizeof(char));
  strcpy(mariadbHandle->handle, handle->handle);
  mariadbHandle->mariadb = mariadb;
  mariadbHandles[numHandles++] = mariadbHandle;

  return SUCCESS;
}


int driverMariaDB_disconnect(struct xsb_connectionHandle* handle)
{
  int i, j;

  for (i = 0 ; i < numHandles ; i++)
    {
      if (!strcmp(handle->handle, mariadbHandles[i]->handle))
	{
	  mysql_close(mariadbHandles[i]->mariadb);
	  freeConnection(mariadbHandles[i]);
	  for (j = i + 1 ; j < numHandles ; j++)
	    mariadbHandles[j-1] = mariadbHandles[j];
	  numHandles--;
	  break;
	}
    }

  return SUCCESS;
}


struct xsb_data** driverMariaDB_query(struct xsb_queryHandle* handle)
{
  struct driverMariaDB_connectionInfo* connection;
  struct driverMariaDB_queryInfo* query;
  MYSQL_RES* resultSet;
  int i,n;

  query = NULL;
  connection = NULL;
  resultSet = NULL;
  if (handle->state == QUERY_RETRIEVE)
    {
      for (i = 0 ; i < numQueries ; i++)
	{
	  if (!strcmp(mariadbQueries[i]->handle, handle->handle))
	    {
	      query = mariadbQueries[i];
	      break;
	    }
	}
    }
  else if (handle->state == QUERY_BEGIN)
    {
      for (i = 0 ; i < numHandles ; i++)
	{
	  if (!strcmp(mariadbHandles[i]->handle, handle->connHandle->handle))
	    {
	      connection = mariadbHandles[i];
	      break;
	    }
	}
      query = (struct driverMariaDB_queryInfo *)malloc(sizeof(struct driverMariaDB_queryInfo));
      query->handle = (char *)malloc((strlen(handle->handle) + 1) * sizeof(char));
      strcpy(query->handle, handle->handle);
      query->query = (char *)malloc((strlen(handle->query) + 1) * sizeof(char));
      strcpy(query->query, handle->query);
      query->connection = connection;
      query->resultSet = NULL;

      if (mysql_query(query->connection->mariadb, query->query))
	{
	  driverMariaDB_error(query->connection->mariadb);
	  freeQueryInfo(query);
	  return NULL;	
	}
      else
	{
	  if ((resultSet = mysql_store_result(query->connection->mariadb)) == NULL)
	    {
	      freeQueryInfo(query);
	      return NULL;
	    }
	  query->resultSet = resultSet;
	  mariadbQueries[numQueries++] = query;
	  handle->state = QUERY_RETRIEVE;
	  n = mysql_num_fields(resultSet);
	  handle->numResultCols = n;
	  query->returnFields = n;
	}
    }

  return driverMariaDB_getNextRow(query);
}


static struct xsb_data** driverMariaDB_getNextRow(struct driverMariaDB_queryInfo* query)
{
  struct xsb_data** result;
  MYSQL_ROW row;
  int numFields;
  int i, j;
  char** p_temp=NULL;

  result = NULL;
  if ((row = mysql_fetch_row(query->resultSet)) == NULL)
    {
      if (mysql_errno(query->connection->mariadb))
	driverMariaDB_error(query->connection->mariadb);
      else
	{
	  for (i = 0 ; i < numQueries ; i++)
	    {
	      if (!strcmp(mariadbQueries[i]->handle, query->handle))
		{
		  freeQueryInfo(query);
		  for (j = i + 1 ; j < numQueries ; j++)
		    mariadbQueries[j-1] = mariadbQueries[j];
		  numQueries--;
		}
	    }
	}
      return NULL;
    }

  numFields = query->returnFields;
  result = (struct xsb_data **)malloc(numFields * sizeof(struct xsb_data *));
  for (i = 0 ; i < numFields ; i++) {
      result[i] = (struct xsb_data *)malloc(sizeof(struct xsb_data));
      result[i]->val = (union xsb_value *)malloc(sizeof(union xsb_value));
      result[i]->type = driverMariaDB_getXSBType(mysql_fetch_field_direct(query->resultSet, i));

      if (row[i] == NULL)
	result[i]->type = NULL_VALUE_TYPE;

      switch (result[i]->type) {
	case INT_TYPE:
	  result[i]->val->i_val = strtol(row[i],p_temp,10);
	  break;

	case FLOAT_TYPE:
	  result[i]->val->f_val = strtod(row[i],p_temp);
	  break;

	case STRING_TYPE:
	  result[i]->val->str_val = (char *)malloc((strlen(row[i])+1) * sizeof(char));
	  strcpy(result[i]->val->str_val, (char *)row[i]);
	  break;

	case NULL_VALUE_TYPE:
	  break;
	}
    }

  return result;
}


/***** PREPARED STATEMENT FUNCTIONALITY (for MySQL 5.1 version) *****/


int driverMariaDB_prepareStatement(struct xsb_queryHandle* handle)
{
  struct driverMariaDB_preparedresultset* rs;
  MYSQL* mariadb;
  MYSQL_STMT* stmt;
  MYSQL_RES* res;
  int i;
  char* sqlQuery;
  int numResultCols;
  MYSQL_FIELD* field;

  sqlQuery = (char *)malloc((strlen(handle->query) + 1) * sizeof(char));
  strcpy(sqlQuery, handle->query);
	
  mariadb = NULL;	

  for (i = 0 ; i < numHandles ; i++)
    {
      if (!strcmp(mariadbHandles[i]->handle, handle->connHandle->handle))
	{
	  mariadb = mariadbHandles[i]->mariadb;
	  break;
	}
    }

  if ((stmt = mysql_stmt_init(mariadb)) == NULL)
    {
      errorMesg = "mysql_stmt_init() failed\n";
      //errorMesg = mysql_stmt_error(stmt);
      free(sqlQuery);
      sqlQuery = NULL;
      return FAILURE;		
    }
  if ( mysql_stmt_prepare(stmt, sqlQuery, (unsigned long)strlen(sqlQuery))) {
    errorMesg = mysql_stmt_error(stmt);
    free(sqlQuery);
    sqlQuery = NULL;
    return FAILURE;		
  }

  rs = (struct driverMariaDB_preparedresultset *)malloc(sizeof(struct driverMariaDB_preparedresultset));
  rs->statement = stmt;

  res = mysql_stmt_result_metadata(stmt);

  numResultCols = 0;
  if (res == NULL)
    {
      if (mysql_errno(mariadb))
	{
	  errorMesg = mysql_stmt_error(stmt);
	  free(sqlQuery);
	  sqlQuery = NULL;
	  free(rs);
	  rs = NULL;
	  return FAILURE;
	}
    }
  else numResultCols = mysql_num_fields(res);

  rs->returnFields = numResultCols;

  handle->numParams = mysql_stmt_param_count(stmt);
  handle->numResultCols = rs->returnFields;
  handle->state = QUERY_BEGIN;
	
  rs->handle = handle;
  rs->bindResult = NULL;
	
  rs->metaInfo = (struct xsb_data **)malloc(rs->returnFields * sizeof(struct xsb_data *));
  for (i = 0 ; i < rs->returnFields ; i++)
    {
      rs->metaInfo[i] = (struct xsb_data *)malloc(sizeof(struct xsb_data));
      field = mysql_fetch_field_direct(res, i);
      rs->metaInfo[i]->type = driverMariaDB_getXSBType(field);
      rs->metaInfo[i]->length = field->length;
    }
  prepQueries[numPrepQueries++] = rs;

  free(sqlQuery);
  sqlQuery = NULL;

  return rs->handle->numParams;
}

struct xsb_data** driverMariaDB_execPrepareStmt(struct xsb_data** bindValues, struct xsb_queryHandle* handle)
{
  struct driverMariaDB_preparedresultset* rs;
  int i, numOfParams;
  MYSQL_BIND *bind, *bindResult;
	
  Integer *intTemp;
  double *doubleTemp;
  unsigned long *lengthTemp;
  char *charTemp;

  rs = NULL;

  for (i = 0 ; i < numPrepQueries; i++)
    {
      if (!strcmp(prepQueries[i]->handle->handle, handle->handle))
	{
	  rs = prepQueries[i];
	  break;
	}
    }

  if (rs == NULL)
    {
      errorMesg = "no specified query handle exists";
      return NULL;
    }
  if (handle->state == QUERY_RETRIEVE)
    {
      return driverMariaDB_prepNextRow(rs);		
    }
	
  numOfParams = rs->handle->numParams;
  bind = (MYSQL_BIND *)calloc( numOfParams, sizeof(MYSQL_BIND));
  memset(bind, 0, sizeof(*bind));
  for (i = 0 ; i < numOfParams ; i++)
    {
      if (bindValues[i]->type == INT_TYPE)
	{			
	  bind[i].buffer_type = MYSQL_TYPE_LONG;
	  intTemp = malloc (sizeof(Integer));
	  *intTemp = bindValues[i]->val->i_val;
	  bind[i].buffer = intTemp;
	  bind[i].is_null = calloc(1,sizeof(_Bool));
	}
      else if (bindValues[i]->type == FLOAT_TYPE)
	{		        
	  bind[i].buffer_type = MYSQL_TYPE_DOUBLE;
	  doubleTemp = (double*)malloc (sizeof(double));
	  *doubleTemp = bindValues[i]->val->f_val;
	  bind[i].buffer = doubleTemp;
	  bind[i].is_null = calloc(1,sizeof(_Bool)) ;  			
	}
      else if (bindValues[i]->type == STRING_TYPE)
	{
	  bind[i].buffer_type = MYSQL_TYPE_STRING;
	  lengthTemp = (unsigned long*)malloc (sizeof(unsigned long));
	  *lengthTemp = (unsigned long)strlen(bindValues[i]->val->str_val);
	  bind[i].length = lengthTemp;
	  bind[i].buffer_length = (unsigned long)strlen(bindValues[i]->val->str_val);
	  bind[i].is_null = calloc(1,sizeof(_Bool)) ;    
	  charTemp = (char*)malloc((strlen(bindValues[i]->val->str_val)+1) * sizeof(char));
	  strcpy( charTemp, bindValues[i]->val->str_val);
	  bind[i].buffer = charTemp;
	}
    }
  if (mysql_stmt_bind_param(rs->statement, bind))
    {
      errorMesg = mysql_stmt_error(rs->statement);
      freeBind(bind,numOfParams);
      return NULL;
    }
  if (mysql_stmt_execute(rs->statement))
    {
      errorMesg = mysql_stmt_error(rs->statement);
      freeBind(bind,numOfParams);
      return NULL;
    }

  if (rs->returnFields == 0)
    {
      freeBind(bind,numOfParams);
      return NULL;
    }

  bindResult = (MYSQL_BIND *)malloc(rs->returnFields * sizeof(MYSQL_BIND));
  memset(bindResult, 0, sizeof(*bindResult));
  for (i = 0 ; i < rs->returnFields ; i++)
    {
      switch (rs->metaInfo[i]->type)
	{
	case INT_TYPE:
	  bindResult[i].buffer_type = MYSQL_TYPE_LONG;
	  bindResult[i].buffer = malloc( sizeof(int) );
	  bindResult[i].is_null = calloc(1,sizeof(_Bool)) ;
	  bindResult[i].length = malloc( sizeof(unsigned long) );
	  bindResult[i].error = calloc(1,sizeof(_Bool)) ; 
	  break;

	case FLOAT_TYPE:
	  bindResult[i].buffer_type = MYSQL_TYPE_DOUBLE;
	  bindResult[i].buffer = malloc( sizeof(double) );
	  bindResult[i].is_null = calloc(1,sizeof(_Bool));
	  bindResult[i].length = malloc( sizeof(unsigned long) ) ;
	  bindResult[i].error = calloc(1,sizeof(_Bool)) ;
	  break;
			
	case STRING_TYPE:
	  bindResult[i].buffer_type = MYSQL_TYPE_VAR_STRING;
	  bindResult[i].buffer_length = (unsigned long)rs->metaInfo[i]->length+1;
	  bindResult[i].buffer = malloc((rs->metaInfo[i]->length+1) * sizeof(char));
	  bindResult[i].is_null = calloc(1,sizeof(_Bool)) ;
	  bindResult[i].length = malloc( sizeof(unsigned long) );
	  *(bindResult[i].length) =  (unsigned long)rs->metaInfo[i]->length+1;
	  bindResult[i].error = calloc(1,sizeof(_Bool)) ;
	  break;
	}
    }
	
  if (mysql_stmt_bind_result(rs->statement, bindResult))
    {
      errorMesg = mysql_stmt_error(rs->statement);
      mysql_stmt_free_result(rs->statement);
      mysql_stmt_reset(rs->statement);
      freeBind(bind,numOfParams);
      freeBind(bindResult,rs->returnFields);
      return NULL;
    }

  if(rs->bindResult!=NULL)
    freeBind(rs->bindResult,rs->returnFields);

  rs->bindResult = bindResult;

  handle->state = QUERY_RETRIEVE;

  freeBind(bind,numOfParams);

  return driverMariaDB_prepNextRow(rs);
}

struct xsb_data** driverMariaDB_prepNextRow(struct driverMariaDB_preparedresultset* rs)
{

  struct xsb_data ** result = NULL;
  MYSQL_BIND *bindResult = rs->bindResult;
  int i;

  int flag;
  flag = mysql_stmt_fetch(rs->statement);
  if (flag == MYSQL_NO_DATA)
    {
      mysql_stmt_free_result(rs->statement);
      mysql_stmt_reset(rs->statement);
      return NULL;
    }

  result = (struct xsb_data **)malloc(rs->returnFields * sizeof(struct xsb_data *));
  for ( i = 0 ; i < rs->returnFields ; i++){

    result[i] = (struct xsb_data *)malloc(sizeof(struct xsb_data));
    result[i]->type = rs->metaInfo[i]->type;
    result[i]->length = rs->metaInfo[i]->length;
    result[i]->val = (union xsb_value *)malloc(sizeof(union xsb_value));
    result[i]->val->str_val = NULL;

    switch (result[i]->type){
    case INT_TYPE:
      result[i]->val->i_val = *( (int*) bindResult[i].buffer );
      break;
    case FLOAT_TYPE:
      result[i]->val->f_val = *( (double*) bindResult[i].buffer );
      break;
    case STRING_TYPE:
      result[i]->val->str_val = (char *)malloc((strlen((char *)(bindResult[i].buffer))+1) * sizeof(char));
      strcpy( result[i]->val->str_val, bindResult[i].buffer );
      break;
    }
  }


  return result;
}

int driverMariaDB_closeStatement(struct xsb_queryHandle* handle)
{
  struct driverMariaDB_preparedresultset* rs;
  int i, j;

  for (i = 0 ; i < numPrepQueries ; i++) {
    if (!strcmp(prepQueries[i]->handle->handle, handle->handle)) {

      rs = prepQueries[i];

      for (j = i + 1 ; j < numPrepQueries ; j++)
	prepQueries[j-1] = prepQueries[j];

      freeResultset(rs);
      numPrepQueries--;
      break;

    }
  }

  return SUCCESS;
}

/***** END OF PREPARED STATEMENT FUNCTIONALITY ***** */


char* driverMariaDB_errorMesg()
{
  char* temp;
  if (errorMesg != NULL)
    {
      temp = (char *)malloc((strlen(errorMesg) + 1) * sizeof(char));
      strcpy(temp, errorMesg);
      errorMesg = NULL;
      return temp;
    }
  return NULL;
}

static void driverMariaDB_error(MYSQL* mariadb)
{
  errorMesg = mysql_error(mariadb);
}

static int driverMariaDB_getXSBType(MYSQL_FIELD* field)
{
  int type;

  type = 0;
  switch (field->type)
    {
    case FIELD_TYPE_TINY:
    case FIELD_TYPE_SHORT:
    case FIELD_TYPE_LONG:
    case FIELD_TYPE_INT24:
    case FIELD_TYPE_LONGLONG:
      type = INT_TYPE;
      break;
		
    case FIELD_TYPE_DECIMAL:
    case FIELD_TYPE_FLOAT:
    case FIELD_TYPE_DOUBLE:
      type = FLOAT_TYPE;
      break;

    case FIELD_TYPE_STRING:
    case FIELD_TYPE_DATE:
    case FIELD_TYPE_TIMESTAMP:
    case FIELD_TYPE_TIME:
    case FIELD_TYPE_DATETIME:
    case FIELD_TYPE_YEAR:
    case FIELD_TYPE_NEWDATE:
    case FIELD_TYPE_ENUM:
    case FIELD_TYPE_SET:
    case FIELD_TYPE_TINY_BLOB:
    case FIELD_TYPE_MEDIUM_BLOB:
    case FIELD_TYPE_LONG_BLOB:
    case FIELD_TYPE_BLOB:
    case FIELD_TYPE_VAR_STRING:
    case FIELD_TYPE_NULL:
    default:
      type = STRING_TYPE;
      break;
    }

  return type;
}

void driverMariaDB_freeResult(struct xsb_data** result, int numOfElements)
{
  int i;
  if (result != NULL) {
    for (i=0; i<numOfElements; i++) {
      if(result[i]!=NULL){
	if(result[i]->val != NULL){
	  if(result[i]->type == STRING_TYPE && result[i]->val->str_val != NULL )
	    { 
	      free(result[i]->val->str_val);
	      result[i]->val->str_val = NULL;
	    }

	  free(result[i]->val);
	  result[i]->val = NULL;
	}
	free(result[i]);
	result[i]= NULL;
      }
    }
    free(result);
    result = NULL;
  }
  return;
}


DllExport int call_conv driverMariaDB_register(void)
{
  union functionPtrs* funcConnect;
  union functionPtrs* funcDisconnect;
  union functionPtrs* funcQuery;
  union functionPtrs* funcErrorMesg;
  union functionPtrs* funcPrepare;
  union functionPtrs* funcExecPrepare;
  union functionPtrs* funcCloseStmt;
  union functionPtrs* funcFreeResult;

  registerXSBDriver("mariadb", NUMBER_OF_MYSQL_DRIVER_FUNCTIONS);

  funcConnect = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcConnect->connectDriver = driverMariaDB_connect;
  registerXSBFunction("mariadb", CONNECT, funcConnect);

  funcDisconnect = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcDisconnect->disconnectDriver = driverMariaDB_disconnect;
  registerXSBFunction("mariadb", DISCONNECT, funcDisconnect);

  funcQuery = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcQuery->queryDriver = driverMariaDB_query;
  registerXSBFunction("mariadb", QUERY, funcQuery);

  funcPrepare = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcPrepare->prepareStmtDriver = driverMariaDB_prepareStatement;
  registerXSBFunction("mariadb", PREPARE, funcPrepare);

  funcExecPrepare = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcExecPrepare->executeStmtDriver = driverMariaDB_execPrepareStmt;
  registerXSBFunction("mariadb", EXEC_PREPARE, funcExecPrepare);

  funcCloseStmt = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcCloseStmt->closeStmtDriver = driverMariaDB_closeStatement;
  registerXSBFunction("mariadb", CLOSE_STMT, funcCloseStmt);
	
  funcErrorMesg = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcErrorMesg->errorMesgDriver = driverMariaDB_errorMesg;
  registerXSBFunction("mariadb", ERROR_MESG, funcErrorMesg);

  funcFreeResult = (union functionPtrs *)malloc(sizeof(union functionPtrs));
  funcFreeResult->freeResultDriver = driverMariaDB_freeResult;
  registerXSBFunction("mariadb", FREE_RESULT, funcFreeResult);

  return TRUE;
}

void freeQueryInfo(struct driverMariaDB_queryInfo* query)
{
  if (query == NULL)
    return;


  if (query->handle != NULL)
    { free(query->handle);
      query->handle = NULL;
    }

  if (query->query != NULL)
    { free(query->query);
      query->query = NULL;
    }

  if (query->resultSet != NULL)
    mysql_free_result(query->resultSet);
  //  if (query->resultSet != NULL)
  //free(query->resultSet);
  
  free(query);
  query = NULL;
  return;
}

void freeConnection(struct driverMariaDB_connectionInfo* connection)
{
  if (connection == NULL)
    return;

  if (connection->handle!= NULL) {
    free(connection->handle);
    connection->handle = NULL;
  }
  free(connection);
  connection = NULL;
  return;
}

void freeMetaInfo(struct xsb_data** metaInfo, int num)
{
  int i;
  if (metaInfo != NULL) {
    for (i=0; i<num; i++) {
      if(metaInfo[i]!=NULL)
	{ free(metaInfo[i]);
	  metaInfo[i] = NULL;
	}
    }
    free(metaInfo);
    metaInfo = NULL;
  }
  return;
}

void freeResultset(struct driverMariaDB_preparedresultset* rs)
{

  if (rs == NULL)
    return;

  freeMetaInfo(rs->metaInfo,rs->returnFields);
  freeBind(rs->bindResult,rs->returnFields);

  if ( rs->statement != NULL )
    {
      mysql_stmt_free_result(rs->statement); 
      mysql_stmt_close(rs->statement);
    }

  free(rs);
  rs = NULL;
  return;
}

void freeBind(MYSQL_BIND* bind, int num)
{

  int i;

  if (bind != NULL) {
    for (i=0; i<num; i++) {
      if ( bind[i].buffer != NULL ) free(bind[i].buffer);
      if ( bind[i].is_null != NULL ) free(bind[i].is_null);
      if ( bind[i].length != NULL ) free(bind[i].length);
      if ( bind[i].error != NULL ) free(bind[i].error);
    }
    free(bind);
    bind = NULL;
  }
  return;

}
