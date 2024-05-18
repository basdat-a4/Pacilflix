from psycopg2 import connect
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from dotenv import load_dotenv
from os import environ

load_dotenv(override=True)

dbname = environ.get('DB_NAME')
user = environ.get('DB_USER')
password = environ.get('DB_PASSWORD')
host = environ.get('DB_HOST')
port = environ.get('DB_PORT', 5432)


def migrate():
    print('Migrating...')
    load_dotenv(override=True)

    connection = connect(
        dbname=dbname,
        user=user,
        password=password,
        host=host,
        port=port,
    )
    connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    print('CONNECTION SUCCESS!')

    cursor = connection.cursor()
    with open('SQL_A_4.sql', 'r') as sql_file:
        sql_commands = sql_file.read()
    cursor.execute(sql_commands)
    print('SUCCESS MIGRATE!')

    cursor.close()
    connection.close()


def reset():
    print('Resetting DB...')
    load_dotenv(override=True)

    connection = connect(
        dbname=dbname,
        user=user,
        password=password,
        host=host,
        port=port
    )
    connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    print('CONNECTION SUCCESS!')

    cursor = connection.cursor()
    try:
        cursor.execute('DROP SCHEMA pacilflix CASCADE')
        print('Success drop schema!')
    except:
        pass
    migrate()

    cursor.close()
    connection.close()


if __name__ == '__main__':
    reset()
