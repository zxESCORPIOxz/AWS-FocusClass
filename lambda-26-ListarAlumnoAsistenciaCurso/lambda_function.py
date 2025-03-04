from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date
from decimal import Decimal

LISTAR_ASISTENCIA_PROC = "ListarAsistenciaPorAlumnoCurso"

def convert_value(value):
    """Convierte valores no serializables a formatos JSON-friendly."""
    if isinstance(value, date):
        return value.strftime('%Y-%m-%d')
    if isinstance(value, Decimal):
        return float(value)
    return value

def lambda_handler(event, context):
    connection = None
    cursor = None

    try:
        body = json.loads(event.get('body', '{}'))
        token = body.get('token')
        id_alumno_matricula = body.get('id_alumno_matricula')
        id_curso = body.get('id_curso')

        print("Validando token recibido:", token)
        token_result = validate_token(token)

        if token_result['status'] != SUCCESS:
            print("Token no válido:", token_result['message'])
            return {
                "statusCode": 401,
                "body": json.dumps({
                    "status": LOGOUT,
                    "message": "Tu sesión ha expirado o es inválida. Por favor, inicia sesión nuevamente."
                })
            }

        print("Token válido, listando asistencia para el alumno:", id_alumno_matricula, "curso:", id_curso)

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        cursor.callproc(LISTAR_ASISTENCIA_PROC, [id_alumno_matricula, id_curso])
        asistencia = []
        for result in cursor.stored_results():
            asistencia.extend(result.fetchall())

        asistencia_json = [
            {desc[0]: convert_value(value) for desc, value in zip(result.description, row)}
            for row in asistencia
        ]

        response = {
            "statusCode": 200,
            "body": json.dumps({
                "status": SUCCESS,
                "message": "Datos de asistencia obtenidos correctamente.",
                "asistencia": asistencia_json
            })
        }

    except Error as e:
        print("Error en la base de datos:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al obtener los datos de asistencia."
            })
        }
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return response
