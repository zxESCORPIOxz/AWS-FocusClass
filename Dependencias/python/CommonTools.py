from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json

VALIDATE_TOKEN_PROC = "ValidarToken"

def validate_token(token):
    connection = None
    cursor = None
    response = None

    try:
        if not token:
            return {
                "status": LOGOUT,
                "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
            }

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        print(f"Llamando al procedimiento {VALIDATE_TOKEN_PROC} con token: {token}")
        cursor.callproc(VALIDATE_TOKEN_PROC, [token])

        for result in cursor.stored_results():
            response_row = result.fetchone()
            if response_row:
                id_usuario = response_row[0] if len(response_row) > 0 else None
                email = response_row[1] if len(response_row) > 1 else None
                num_documento = response_row[2] if len(response_row) > 2 else None

                if id_usuario and email and num_documento:
                    print("Token válido, datos del usuario obtenidos.")
                    response = {
                        "status": SUCCESS,
                        "message": "Token válido.",
                        "id_usuario": id_usuario,
                        "email": email,
                        "num_documento": num_documento
                    }
                    connection.commit()
                    return response
                else:
                    print("Token inválido o datos incompletos.")
                    response = {
                        "status": LOGOUT,
                        "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
                    }
                    return response

        print("Token no válido.")
        response = {
            "status": LOGOUT,
            "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
        }

    except Error as e:
        print("Error en la validación del token:", str(e))
        response = {
            "status": LOGOUT,
            "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente para continuar."
        }

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return response
