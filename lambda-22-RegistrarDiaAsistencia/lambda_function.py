from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime

REGISTRAR_ASISTENCIA_POR_CURSO_PROC = "RegistrarAsistenciaPorCurso"

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        id_curso = body.get('id_curso')
        fecha = body.get('fecha') 

        print("Validando token recibido:", token)
        token_result = validate_token(token)

        if token_result['status'] != SUCCESS:
            print("Token no válido:", token_result['message'])
            return {
                "statusCode": 401,
                "body": json.dumps({
                    "status": LOGOUT,
                    "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
                })
            }

        print("Token válido, registrando asistencia para el curso:", id_curso, "en la fecha:", fecha)

        try:
            fecha = datetime.strptime(fecha, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "El formato de fecha es inválido. Asegúrese de que sea 'YYYY-MM-DD HH:MM:SS'."
                })
            }

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        cursor.callproc(REGISTRAR_ASISTENCIA_POR_CURSO_PROC, [id_curso, fecha])

        connection.commit()

        response = {
            "statusCode": 200,
            "body": json.dumps({
                "status": SUCCESS,
                "message": "Asistencia registrada correctamente para el curso."
            })
        }

        return response

    except Error as e:
        print("Error al registrar asistencia:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al registrar la asistencia para el curso."
            })
        }
        return response

    except Exception as e:
        print("Error inesperado:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error inesperado al registrar la asistencia."
            })
        }
        return response

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
