const AWS = require('aws-sdk');
const ddb = AWS.DynamoDB.DocumentClient();

const TABLENAME = 'basic-table';

exoprts.handler = async (event, context, callback) => {
  console.log('Received event: ', JSON.stringify(event, null, 2));

  let body = JSON.parse(event.body);

  let statusCode = 200;
  let headers = {
    'Access-Control-Allow-Origin': '*'
  }
  let method = event.httpMethod;

  let response;

  try {
    switch (method) {
      case 'GET':
        response = await getTable();
        break;
      case 'PUT':
        response = await putItem(body);
        break;
      case 'DELETE':
        response = await deleteItem(body);
        break;
    }
  } catch (error) {
    statusCode = 400;
    response = error.message;
  } finally {
    response = JSON.stringify(response);
  }

  callback(null, {
    statusCode,
    body: response,
    headers
  });
}

async function getTable() {
  const params = {
    TableName: TABLENAME
  };

  let response;
  await ddb.scan(params, (err, data) => {
    response = (err ? err : data);
  }).promise()

  return response;
}

async function putItem(body) {
  const params = {
    TableName: TABLENAME,
    Item: body
  };

  let response;
  await ddb.put(params, (err, data) => {
    response = (err ? err : data);
  }).promise()

  return response;
}

async function deleteItem(body) {
  const params = {
    TableName: TABLENAME,
    Key: {
      id: body.id
    }
  };

  let response;
  await ddb.delete(params, (err, data) => {
    response = (err ? err : data);
  }).promise()

  return response;
}
