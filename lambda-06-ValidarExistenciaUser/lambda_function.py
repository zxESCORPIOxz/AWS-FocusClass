from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date

VERIFICAR_USUARIO_PROC = "VerificarUsuario"

def convert_date(value):
    if isinstance(value, date):
        return value.strftime('%Y-%m-%d')
    return value

def lambda_handler(event, context):
    connection = None
    cursor_user = None
    response = None

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        tipo_doc = body.get('tipo_doc')
        num_documento = body.get('num_documento')

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

        print("Token válido, verificando usuario con tipo_doc y num_documento:", tipo_doc, num_documento)

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor_user = connection.cursor()

        cursor_user.callproc(VERIFICAR_USUARIO_PROC, [tipo_doc, num_documento])

        user_data = []
        for result_user in cursor_user.stored_results():
            user_data.extend(result_user.fetchall())

        if user_data:
            status = user_data[0][0]
            if status != SUCCESS:
                response = {
                    "statusCode": 404,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El usuario no existe con el tipo y número de documento proporcionados."
                    })
                }
            else:
                user_json = json.dumps([
                    {desc[0]: convert_date(value) for desc, value in zip(result_user.description, row)} 
                    for row in user_data
                ])

                response = {
                    "statusCode": 200,
                    "body": json.dumps({
                        "status": SUCCESS,
                        "message": "Usuario encontrado.",
                        "user": json.loads(user_json)
                    })
                }
        else:
            response = {
                "statusCode": 404,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "El usuario no existe con el tipo y número de documento proporcionados."
                })
            }

        connection.commit()
        return response

    except Error as e:
        print("Error en la verificación del usuario:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al verificar el usuario."
            })
        }
        return response

    finally:
        if cursor_user:
            cursor_user.close()
        if connection:
            connection.close()
