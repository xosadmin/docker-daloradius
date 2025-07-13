## Docker Daloradius

This is a Docker image for Daloradius.

## How to use it?  
Run the container using the following command:
  
```bash
docker run -d --name daloradius \
  -e MYSQL_SERVER=<host> \
  -e MYSQL_PORT=<port> \
  -e MYSQL_USER=<user> \
  -e MYSQL_PASSWORD=<password> \
  -e MYSQL_DBNAME=<database_name> \
  -p 8000:8000 -p 80:80 \
  xosadmin/docker-daloradius
```
  
#### Note:  
- To avoid from unexpected issue, please use the same database for daloradius and freeradius
- The default login information (username / password): ``administrator`` / ``radius``
- If you have existing DB structure in database, you can use ``-e DO_NOT_IMPORT_DB=true`` to skip DB structure initialization
- For more information, please refer to [https://github.com/lirantal/daloradius](https://github.com/lirantal/daloradius)  
