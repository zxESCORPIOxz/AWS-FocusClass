from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date, datetime

OBTENER_ENTIDADES_PROC = "ObtenerEntidadesPorDNI"
LISTAR_MATRICULAS_PROC = "ListarMatriculas"

def custom_json_serializer(obj):
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    raise TypeError("Type not serializable")

def lambda_handler(event, context):
    connection = None
    cursor_entities = None
    cursor_matriculas = None
    response = None

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')

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

        num_documento = token_result.get('num_documento')
        print("Token válido, obteniendo entidades para num_documento:", num_documento)

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor_entities = connection.cursor()
        cursor_matriculas = connection.cursor()

        cursor_entities.callproc(OBTENER_ENTIDADES_PROC, [num_documento])

        entities = []
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
                "num_documento": num_documento,
                "entities": entities_with_matriculas
            }, default=custom_json_serializer)
        }

        connection.commit()
        return response

    except Error as e:
        print("Error en la obtención de entidades y matrículas:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al obtener las entidades y matrículas."
            })
        }
        return response

    finally:
        if cursor_entities:
            cursor_entities.close()
        if cursor_matriculas:
            cursor_matriculas.close()
        if connection:
            connection.close()
