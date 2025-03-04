from CommonTools import validate_token
from constants import DB_CONFIG, SUCCESS, FAILED, LOGOUT
import mysql.connector
from mysql.connector import Error
import json
from datetime import date
from decimal import Decimal

def convert_date(value):
    if isinstance(value, date):
        return value.strftime('%Y-%m-%d')
    if isinstance(value, Decimal):
        return float(value)
    return value

def lambda_handler(event, context):
    connection = None
    cursor = None
    response = None

    try:
        body = json.loads(event['body']) if 'body' in event else {}
        token = body.get('token')
        id_curso = body.get('id_curso')

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

        print("Token válido, listando alumnos del curso:", id_curso)

        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        # Llamar al procedimiento `ListarAlumnosPorCurso`
        cursor.callproc('ListarAlumnosPorCurso', [id_curso])
        alumnos_data = []
        for result in cursor.stored_results():
            alumnos_data.extend(result.fetchall())

        if not alumnos_data:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "status": FAILED,
                    "message": "No se encontraron alumnos para el curso proporcionado."
                })
            }

        # Construir el JSON con las etapas y notas
        alumnos = []
        for row in alumnos_data:
            alumno = {desc[0]: convert_date(value) for desc, value in zip(result.description, row)}

            # Obtener etapas del alumno
            cursor.callproc('ListarEtapasPorAlumnoCurso', [alumno['id_alumno_matricula'], id_curso])
            etapas_data = []
            for etapas_result in cursor.stored_results():
                etapas_data.extend(etapas_result.fetchall())

            etapas = []
            for etapa_row in etapas_data:
                etapa = {desc[0]: convert_date(value) for desc, value in zip(etapas_result.description, etapa_row)}

                # Obtener notas de la etapa
                cursor.callproc('ListarNotasPorCursoAlumnoEtapa', [alumno['id_alumno_matricula'], id_curso, etapa['id_etapa']])
                notas_data = []
                for notas_result in cursor.stored_results():
                    notas_data.extend(notas_result.fetchall())

                notas = [
                    {desc[0]: convert_date(value) for desc, value in zip(notas_result.description, nota_row)}
                    for nota_row in notas_data
                ]
                etapa['notas'] = notas
                etapas.append(etapa)

            alumno['etapas'] = etapas
            alumnos.append(alumno)

        response = {
            "statusCode": 200,
            "body": json.dumps({
                "status": SUCCESS,
                "message": "Datos listados correctamente.",
                "alumnos": alumnos
            })
        }
        return response

    except Error as e:
        print("Error al listar datos:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({
                "status": FAILED,
                "message": "Ocurrió un error al listar los datos."
            })
        }

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
