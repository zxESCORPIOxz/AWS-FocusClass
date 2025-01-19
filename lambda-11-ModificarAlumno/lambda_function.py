from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
import requests
from datetime import date

IMAGE_UPLOAD_URL = "http://108.181.169.248/IMG-FOCUSCLASS/FileInput.php"
MODIFICAR_PROC = "ModificarAlumno"


def add_mime_prefix(base64_string):
    if not base64_string.startswith("data:image/"):
        return f"data:image/png;base64,{base64_string}"
    return base64_string


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

        id_usuario = body.get('id_usuario')
        nombre = body.get('nombre')
        apellido_paterno = body.get('apellido_paterno')
        apellido_materno = body.get('apellido_materno')
        sexo = body.get('sexo')
        email = body.get('email')
        url_imagen = body.get('url_imagen')
        telefono = body.get('telefono')
        ubigeo = body.get('ubigeo')
        direccion = body.get('direccion')
        fecha_nacimiento = body.get('fecha_nacimiento')
        tipo_doc = body.get('tipo_doc')
        num_documento = body.get('num_documento')
        img_b64 = body.get('img_b64')
        id_institucion = body.get('id_institucion')
        id_matricula = body.get('id_matricula')
        id_seccion = body.get('id_seccion')

        if not id_usuario:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "El ID de usuario es obligatorio para modificar un alumno."
                })
            }

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        if img_b64:
            image_response = requests.post(IMAGE_UPLOAD_URL, json={
                "nombre": f"{num_documento}_{nombre}_{apellido_paterno}",
                "imgb64": add_mime_prefix(img_b64)
            })
            image_result = image_response.json()

            if image_result.get('status') != SUCCESS:
                return {
                    "statusCode": 500,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "Error al subir la imagen al servidor externo."
                    })
                }

            url_imagen = image_result.get('path')

        cursor.callproc(MODIFICAR_PROC, [
            id_usuario,
            nombre,
            apellido_paterno,
            apellido_materno,
            sexo,
            email,
            url_imagen,
            telefono,
            ubigeo,
            direccion,
            fecha_nacimiento,
            tipo_doc,
            num_documento,
            id_institucion,
            id_matricula,
            id_seccion
        ])

        for result in cursor.stored_results():
            modificar_result = result.fetchone()

        if modificar_result:
            status = modificar_result[0]
            if status == "FAILED_USER_NOT_FOUND":
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El usuario no existe."
                    })
                }
            elif status == "FAILED_EMAIL":
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El correo electrónico ya está registrado."
                    })
                }
            elif status == "FAILED_DOC":
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El tipo o número de documento ya está registrado."
                    })
                }

        connection.commit()

        response = {
            "statusCode": 200,
            "body": json.dumps({
                "status": SUCCESS,
                "message": "Usuario modificado exitosamente.",
                "id_usuario": id_usuario
            })
        }

    except Error as e:
        print("Error en la base de datos:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Error en la base de datos. Intenta nuevamente."
            })
        }
    except Exception as e:
        print("Error inesperado:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error inesperado. Por favor, inténtalo más tarde."
            })
        }
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return response
