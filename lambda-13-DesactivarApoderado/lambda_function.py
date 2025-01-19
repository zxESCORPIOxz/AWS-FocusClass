from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json

DESACTIVAR_APODERADO_PROC = "ToggleEstadoApoderado"

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        id_apoderado = body.get('id_apoderado')

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

        print("Token válido, procediendo a cambiar el estado del apoderado con ID:", id_apoderado)

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        cursor.callproc(DESACTIVAR_APODERADO_PROC, [id_apoderado])

        for result in cursor.stored_results():
            result_data = result.fetchone()
            status = result_data[0]
            message = result_data[1]

            if status == SUCCESS:
                response = {
                    "statusCode": 200,
                    "body": json.dumps({
                        "status": SUCCESS,
                        "message": message
                    })
                }
            else:
                response = {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": message
                    })
                }

        connection.commit()
        return response

    except Error as e:
        print("Error al cambiar el estado del apoderado:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al cambiar el estado del apoderado."
            })
        }
        return response

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
