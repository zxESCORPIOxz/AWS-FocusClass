from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date, datetime

LOGIN_PROC = "ValidarUsuarioCredenciales"
OBTENER_ENTIDADES_PROC = "ObtenerEntidadesPorDNI"
LISTAR_MATRICULAS_PROC = "ListarMatriculas"

def custom_json_serializer(obj):
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    raise TypeError("Type not serializable")

def lambda_handler(event, context):
    connection = None
    cursor = None
    cursor_entities = None
    cursor_matriculas = None
    response = None

    print("Evento recibido:", event)

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        email = body.get('email')
        password = body.get('password')

        print("Datos recibidos:", body)

        if not email or not password:
            response = {
                "statusCode": 400,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "Es necesario proporcionar el correo electrónico y la contraseña."
                })
            }
            return response

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()
        cursor_entities = connection.cursor()
        cursor_matriculas = connection.cursor()

        print(f"Llamando al procedimiento {LOGIN_PROC} con email: {email}")
        cursor.callproc(LOGIN_PROC, [email, password])

        for result in cursor.stored_results():
            response_row = result.fetchone()
            if response_row:
                num_documento = response_row[0] if len(response_row) > 0 else None
                token = response_row[1] if len(response_row) > 1 else None
                nombre = response_row[2] if len(response_row) > 2 else None
                ApellPaterno = response_row[3] if len(response_row) > 3 else None
                ApellMaterno = response_row[4] if len(response_row) > 4 else None
                urlImgPerfil = response_row[5] if len(response_row) > 5 else None

                if token and num_documento:
                    print("Login exitoso, token:", token, "num_documento:", num_documento)
                    entities = []

                    print(f"Llamando al procedimiento {OBTENER_ENTIDADES_PROC} con num_documento: {num_documento}")
                    cursor_entities.callproc(OBTENER_ENTIDADES_PROC, [num_documento])

                    for result_entities in cursor_entities.stored_results():
                        entities.extend(result_entities.fetchall())

                    print("Entidades obtenidas:", entities)

                    entities_with_matriculas = []
                    for entity in entities:
                        entity_dict = dict(zip([desc[0] for desc in result_entities.description], entity))
                        id_institucion = entity_dict.get('id_institucion')

                        if id_institucion:
                            print(f"Llamando al procedimiento {LISTAR_MATRICULAS_PROC} con id_institucion: {id_institucion}")
                            cursor_matriculas.callproc(LISTAR_MATRICULAS_PROC, [id_institucion])

                            matriculas = []
                            for result_matriculas in cursor_matriculas.stored_results():
                                matriculas.extend(result_matriculas.fetchall())

                            matriculas_json = [
                                dict(zip([desc[0] for desc in result_matriculas.description], row)) for row in matriculas
                            ]

                            for m in matriculas_json:
                                for key, value in m.items():
                                    if isinstance(value, (date, datetime)):
                                        m[key] = value.isoformat()

                            entity_dict['matriculas'] = matriculas_json
                        else:
                            entity_dict['matriculas'] = []

                        entities_with_matriculas.append(entity_dict)

                    response = {
                        "statusCode": 200,
                        "body": json.dumps({
                            "status": SUCCESS,
                            "message": "",
                            "token": token,
                            "nombre": nombre,
                            "ApellPaterno": ApellPaterno,
                            "ApellMaterno": ApellMaterno,
                            "num_documento": num_documento,
                            "urlImgPerfil": urlImgPerfil,
                            "entities": entities_with_matriculas
                        }, default=custom_json_serializer)
                    }
                    connection.commit()
                    return response

                else:
                    print("Login fallido: token o num_documento inválidos")
                    response = {
                        "statusCode": 401,
                        "body": json.dumps({
                            "status": FAILED,
                            "message": "El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente."
                        })
                    }
                    return response

        print("No se encontraron resultados válidos en el procedimiento almacenado")
        response = {
            "statusCode": 401,
            "body": json.dumps({
                "status": FAILED,
                "message": "El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente."
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
        if cursor_entities:
            cursor_entities.close()
        if cursor_matriculas:
            cursor_matriculas.close()
        if connection:
            connection.close()

        print("Respuesta final:", response)
        return response
