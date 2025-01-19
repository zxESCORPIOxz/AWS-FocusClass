from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date

LISTAR_ALUMNOS_PROC = "ListarAlumnosPorInstitucion"

def convert_date(value):
    if isinstance(value, date):
        return value.strftime('%Y-%m-%d')
    return value

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        id_institucion = body.get('id_institucion')
        id_matricula = body.get('id_matricula')

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

        print("Token válido, listando alumnos de la institución:", id_institucion)

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        cursor.callproc(LISTAR_ALUMNOS_PROC, [id_institucion, id_matricula])

        alumnos_data = []
        for result in cursor.stored_results():
            alumnos_data.extend(result.fetchall())

        if alumnos_data:
            alumnos_json = json.dumps([
                {desc[0]: convert_date(value) for desc, value in zip(result.description, row)} 
                for row in alumnos_data
            ])

            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Alumnos listados correctamente.",
                    "alumnos": json.loads(alumnos_json)
                })
            }
        else:
            response = {
                "statusCode": 404,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "No se encontraron alumnos para la institución proporcionada."
                })
            }

        connection.commit()
        return response

    except Error as e:
        print("Error al listar alumnos:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al listar los alumnos."
            })
        }
        return response

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
