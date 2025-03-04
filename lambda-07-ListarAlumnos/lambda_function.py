from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date

LISTAR_ALUMNOS_PROC = "ListarAlumnosPorInstitucion"
LISTAR_APODERADOS_PROC = "ListarApoderadosPorAlumno"

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
            alumnos_list = []

            for row in alumnos_data:
                alumno = {desc[0]: convert_date(value) for desc, value in zip(result.description, row)}

                # Obtener los apoderados para el alumno actual
                apoderados = []
                cursor.callproc(LISTAR_APODERADOS_PROC, [alumno['id_alumno']])
                for apoderado_result in cursor.stored_results():
                    apoderados.extend([{
                        desc[0]: convert_date(value) for desc, value in zip(apoderado_result.description, apoderado_row)
                    } for apoderado_row in apoderado_result.fetchall()])

                alumno['apoderados'] = apoderados
                alumnos_list.append(alumno)

            response = {
                "statusCode": 200,
                "body": json.dumps({
                    "status": SUCCESS,
                    "message": "Alumnos listados correctamente.",
                    "alumnos": alumnos_list
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
