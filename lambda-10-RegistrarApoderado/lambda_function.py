from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
import requests

REGISTRAR_PROC = "RegistrarAlumno"
REGISTRAR_EXISTENTE_PROC = "RegistrarAlumnoUserExist"
IMAGE_UPLOAD_URL = "http://108.181.169.248/IMG-FOCUSCLASS/FileInput.php"


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

        if id_usuario: 
            connection = mysql.connector.connect(**DB_CONFIG)
            cursor = connection.cursor()

            cursor.callproc(REGISTRAR_EXISTENTE_PROC, [
                id_usuario,
                id_institucion,
                id_matricula,
                id_seccion
            ])

            for result in cursor.stored_results():
                registro_result = result.fetchone()

            if registro_result and registro_result[0] == "FAILED_ALREADY_REGISTERED":
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El usuario ya está registrado como alumno."
                    })
                }
            elif registro_result and registro_result[0] == "FAILED_USER_NOT_FOUND":
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El usuario no existe."
                    })
                }

            id_alumno = registro_result[2]
            connection.commit()

            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Usuario existente registrado como alumno exitosamente.",
                    "id_usuario": id_usuario,
                    "id_alumno": id_alumno
                })
            }

        else:
            required_fields = [
                nombre, apellido_paterno, apellido_materno, sexo, email,
                telefono, ubigeo, direccion, fecha_nacimiento, tipo_doc,
                num_documento, img_b64, id_institucion, id_matricula, id_seccion
            ]

            if not all(required_fields):
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "Faltan uno o más campos requeridos."
                    })
                }

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
                        "message": "Error al guardar la imagen en el servicio externo."
                    })
                }

            url_imagen = image_result.get('path')

            connection = mysql.connector.connect(**DB_CONFIG)
            cursor = connection.cursor()

            cursor.callproc(REGISTRAR_PROC, [
                nombre, apellido_paterno, apellido_materno, sexo, email,
                url_imagen, telefono, ubigeo, direccion, fecha_nacimiento,
                tipo_doc, num_documento, id_institucion, id_matricula, id_seccion
            ])

            for result in cursor.stored_results():
                registro_result = result.fetchone()

            if registro_result and registro_result[0] == "FAILED_EMAIL":
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El correo electrónico ya está registrado."
                    })
                }
            elif registro_result and registro_result[0] == "FAILED_DOC":
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "status": FAILED,
                        "message": "El tipo o número de documento ya está registrado."
                    })
                }

            id_usuario = registro_result[1]
            id_alumno = registro_result[2]
            connection.commit()

            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Usuario registrado exitosamente.",
                    "id_usuario": id_usuario,
                    "id_alumno": id_alumno
                })
            }

    except Error as e:
        print("Error en el proceso:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error durante el registro."
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
