from constants import DB_CONFIG, SUCCESS, FAILED
import mysql.connector
import json

CAMBIAR_CONTRASENA_PROC = "CambiarContrasena"

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    print("Evento recibido:", event)

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        email = body.get('email')
        recovery_code = body.get('codigo_recuperacion')
        new_password = body.get('nueva_contrasena')

        print("Datos recibidos:", body)

        if not email or not recovery_code or not new_password:
            response = {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "Es necesario proporcionar el correo electrónico, el código de recuperación y la nueva contraseña."
                })
            }
            return response

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        print(f"Llamando al procedimiento {CAMBIAR_CONTRASENA_PROC} con email: {email}")
        cursor.callproc(CAMBIAR_CONTRASENA_PROC, [email, recovery_code, new_password])

        for result in cursor.stored_results():
            response_row = result.fetchone()
            if response_row and response_row[0] == 'SUCCESS':
                print("Contraseña actualizada exitosamente")
                response = {
                    "statusCode": 200,
                    "body": json.dumps({
                        "status": SUCCESS,
                        "message": "La contraseña se actualizó correctamente."
                    })
                }
                connection.commit()
            else:
                print("Error en el proceso de actualización de contraseña")
                response = {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El correo electrónico o el código de recuperación no son válidos."
                    })
                }
            return response

    except Exception as e:
        print("Error en la ejecución:", str(e))
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

        print("Respuesta final:", response)
        return response
