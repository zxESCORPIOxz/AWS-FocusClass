from constants import DB_CONFIG, SUCCESS, FAILED
import mysql.connector
from mysql.connector import Error
import json
import requests  # Asegúrate de tener instalada esta dependencia: `pip install requests`

REGISTRAR_PROC = "RegistrarUsuario"
IMAGE_UPLOAD_URL = "http://108.181.169.248/IMG-FOCUSCLASS/FileInput.php"

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    print("Evento recibido:", event)

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        nombre = body.get('nombre')
        apellido_paterno = body.get('apellido_paterno')
        apellido_materno = body.get('apellido_materno')
        sexo = body.get('sexo')
        email = body.get('email')
        password = body.get('password')
        telefono = body.get('telefono')
        ubigeo = body.get('ubigeo')
        direccion = body.get('direccion')
        fecha_nacimiento = body.get('fecha_nacimiento')
        tipo_doc = body.get('tipo_doc')
        num_documento = body.get('num_documento')
        img_b64 = body.get('img_b64')

        required_fields = [
            nombre, apellido_paterno, 
            apellido_materno, sexo, 
            email, password, 
            telefono, ubigeo, 
            direccion, fecha_nacimiento, 
            tipo_doc, num_documento, img_b64]
        
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
            nombre, apellido_paterno, apellido_materno, sexo, email, password,
            url_imagen, telefono, ubigeo, direccion, fecha_nacimiento, tipo_doc, num_documento
        ])

        for result in cursor.stored_results():
            registro_result = result.fetchone()

        connection.commit()

        if registro_result and registro_result[0] == SUCCESS:
            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Usuario registrado exitosamente."
                })
            }
        elif registro_result and registro_result[0] == "FAILED_EMAIL":
            response = {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "El correo electrónico ya está registrado."
                })
            }
        elif registro_result and registro_result[0] == "FAILED_DOC":
            response = {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "El tipo de documento o número de documento ya está registrado."
                })
            }
        else:
            response = {
                "statusCode": 500,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "Error al registrar el usuario en la base de datos."
                })
            }


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


def add_mime_prefix(base64_string):
    if not base64_string.startswith("data:image/"):
        return f"data:image/png;base64,{base64_string}"
    return base64_string