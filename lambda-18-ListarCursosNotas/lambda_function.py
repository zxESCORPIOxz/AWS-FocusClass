import json
import mysql.connector
from mysql.connector import Error
from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
from datetime import date

LISTAR_CURSOS_PROC = "ListarCursosPorDocenteConDetalle"

def convert_date(value):
    return value.strftime("%Y-%m-%d") if isinstance(value, date) else value

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')

        print("Validando token recibido:", token)
        token_result = validate_token(token)

        if token_result['status'] != SUCCESS:
            return {
                "statusCode": 401,
                "body": json.dumps({
                    "status": LOGOUT,
                    "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
                })
            }

        id_docente = body.get('id_docente')

        if not id_docente:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "Falta el campo 'id_docente'."
                })
            }

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        cursor.callproc(LISTAR_CURSOS_PROC, [id_docente])

        cursos_data = []
        for result in cursor.stored_results():
            cursos_data.extend(result.fetchall())

        cursos = [
            {desc[0]: convert_date(value) for desc, value in zip(result.description, row)}
            for row in cursos_data
        ]

        if cursos:
            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Lista de cursos obtenida exitosamente.",
                    "cursos": cursos
                })
            }
        else:
            response = {
                "statusCode": 404,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "No se encontraron cursos para el docente especificado."
                })
            }

    except Error as e:
        print("Error en el proceso:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al consultar los cursos."
            })
        }
    except Exception as e:
        print("Error inesperado:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error inesperado. Por favor, inténtelo más tarde."
            })
        }
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return response
