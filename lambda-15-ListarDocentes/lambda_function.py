import json
import mysql.connector
from mysql.connector import Error
from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
from datetime import date

LISTAR_DOCENTES_PROC = "ListarDocentesPorInstitucion"
LISTAR_CURSOS_PROC = "ListarCursosPorDocente"

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

        id_institucion = body.get('id_institucion')

        if not id_institucion:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "Falta el campo 'id_institucion'."
                })
            }

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        # Llamar al procedimiento para listar docentes
        cursor.callproc(LISTAR_DOCENTES_PROC, [id_institucion])

        docentes_data = []
        for result in cursor.stored_results():
            docentes_data.extend(result.fetchall())

        docentes = []
        for docente_row in docentes_data:
            docente = {desc[0]: convert_date(value) for desc, value in zip(result.description, docente_row)}

            # Obtener cursos asociados al docente
            cursos_cursor = connection.cursor()
            cursos_cursor.callproc(LISTAR_CURSOS_PROC, [docente['id_docente']])

            cursos_data = []
            for cursos_result in cursos_cursor.stored_results():
                cursos_data.extend(cursos_result.fetchall())

            cursos = [
                {desc[0]: convert_date(value) for desc, value in zip(cursos_result.description, row)}
                for row in cursos_data
            ]

            docente['cursos'] = cursos
            cursos_cursor.close()
            docentes.append(docente)

        if docentes:
            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Lista de docentes obtenida exitosamente.",
                    "docentes": docentes
                })
            }
        else:
            response = {
                "statusCode": 404,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "No se encontraron docentes para la institución especificada."
                })
            }

    except Error as e:
        print("Error en el proceso:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al consultar los docentes."
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
