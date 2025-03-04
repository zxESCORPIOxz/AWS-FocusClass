from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date
from decimal import Decimal

LISTAR_CURSOS_PROC = "ListarCursosPorAlumnoMatricula"
LISTAR_ETAPAS_PROC = "ListarEtapasPorAlumnoCurso"
LISTAR_NOTAS_PROC = "ListarNotasPorCursoAlumnoEtapa"

def convert_value(value):
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

        print("Token válido, listando cursos para el alumno:", id_alumno_matricula)

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        cursor.callproc(LISTAR_CURSOS_PROC, [id_alumno_matricula])
        cursos = []
        for result in cursor.stored_results():
            cursos.extend(result.fetchall())

        cursos_json = [
            {desc[0]: convert_value(value) for desc, value in zip(result.description, row)}
            for row in cursos
        ]

        for curso in cursos_json:
            id_curso = curso["id_curso"]
            curso["etapas"] = []

            cursor.callproc(LISTAR_ETAPAS_PROC, [id_alumno_matricula, id_curso])
            etapas = []
            for result in cursor.stored_results():
                etapas.extend(result.fetchall())

            etapas_json = [
                {desc[0]: convert_value(value) for desc, value in zip(result.description, row)}
                for row in etapas
            ]

            for etapa in etapas_json:
                id_etapa = etapa["id_etapa"]
                etapa["notas"] = []

                cursor.callproc(LISTAR_NOTAS_PROC, [id_alumno_matricula, id_curso, id_etapa])
                notas = []
                for result in cursor.stored_results():
                    notas.extend(result.fetchall())

                etapa["notas"] = [
                    {desc[0]: convert_value(value) for desc, value in zip(result.description, row)}
                    for row in notas
                ]

                curso["etapas"].append(etapa)

        response = {
            "statusCode": 200,
            "body": json.dumps({
                "status": SUCCESS,
                "message": "Datos obtenidos correctamente.",
                "cursos": cursos_json
            })
        }

    except Error as e:
        print("Error en la base de datos:", str(e))
        response = {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al obtener los datos."
            })
        }
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return response
