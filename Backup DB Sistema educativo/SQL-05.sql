-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 11-02-2025 a las 01:36:48
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sistema_educativo`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CambiarContrasena` (IN `p_email` VARCHAR(255), IN `p_codigo_recuperacion` VARCHAR(50), IN `p_nueva_contrasena` VARCHAR(255))   BEGIN
    -- Declarar variable para contar coincidencias
    DECLARE cuenta INT;

    -- Verificar si el email y código de recuperación son válidos
    SELECT COUNT(*) INTO cuenta
    FROM usuario
    WHERE email = p_email AND codigo_recuperacion = p_codigo_recuperacion;

    -- Si existe una coincidencia, actualizar la contraseña
    IF cuenta = 1 THEN
        UPDATE usuario
        SET password = p_nueva_contrasena,
            codigo_recuperacion = NULL -- Limpiar el código de recuperación
        WHERE email = p_email AND codigo_recuperacion = p_codigo_recuperacion;

        SELECT 'SUCCESS' AS resultado;
    ELSE
        -- Si no coinciden el email o el código
        SELECT 'FAILED' AS resultado;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DesactivarAlumno` (IN `p_id_alumno` INT)   BEGIN
    IF EXISTS (SELECT 1 FROM alumno WHERE id_alumno = p_id_alumno) THEN
        UPDATE alumno
        SET estado = 'Inactivo'
        WHERE id_alumno = p_id_alumno;

        SELECT 'SUCCESS' AS status, 'El alumno ha sido desactivado correctamente.' AS message;
    ELSE
        SELECT 'FAILED' AS status, 'No se encontró un alumno con el ID proporcionado.' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GenerarCodigoRecuperacion` (IN `p_email` VARCHAR(255))   BEGIN
    DECLARE v_codigo_recuperacion INT;
    DECLARE v_usuario_existente INT;

    -- Verificar si el usuario con el correo existe
    SELECT COUNT(*) INTO v_usuario_existente
    FROM usuario
    WHERE email = p_email;

    IF v_usuario_existente = 0 THEN
        -- Si no existe el usuario, devolver FAILED
        SELECT 'FAILED' AS status;
    ELSE
        -- Generar un código numérico de 6 dígitos
        SET v_codigo_recuperacion = FLOOR(100000 + (RAND() * 900000));

        -- Actualizar el campo codigo_recuperacion con el nuevo código generado
        UPDATE usuario
        SET codigo_recuperacion = v_codigo_recuperacion
        WHERE email = p_email;

        -- Devolver SUCCESS con el código generado
        SELECT 'SUCCESS' AS status, v_codigo_recuperacion AS codigo_recuperacion;
    END IF;

END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarAlumnosConAsistenciaPorCurso` (IN `p_id_curso` INT, IN `p_fecha` DATE)   BEGIN
    SELECT 
        a.id_alumno,
        a.id_usuario,
        a.id_institucion,
        a.codigo_alumno,
        a.estado AS estado_alumno,
        am.id_alumno_matricula,
        u.apellido_paterno,
        u.apellido_materno,
        u.nombre,
        u.sexo,
        u.email,
        u.url_imagen,
        u.telefono,
        u.ubigeo,
        u.direccion,
        u.fecha_nacimiento,
        u.tipo_doc,
        u.num_documento,
        u.estado AS estado_usuario,
        am.id_matricula,
        m.nombre_matricula,
        m.anio_academico,
        am.fecha_inscripcion,
        s.id_seccion,
        s.nombre AS nombre_seccion,
        s.limite_cupo,
        s.turno,
        g.id_grado,
        g.nombre AS nombre_grado,
        n.id_nivel,
        n.nombre AS nombre_nivel,
        a1.id_asistencia,
        a1.estado AS estado_asistencia,
        a1.observaciones,
        a1.fecha,
        (SELECT 
            ROUND(
                (SUM(CASE WHEN a2.estado = 'PRESENTE' THEN 1 ELSE 0 END) / COUNT(a2.id_asistencia)) * 100, 2
            ) 
         FROM asistencia a2
         WHERE a2.id_alumno_matricula_curso = amc.id_alumno_matricula_curso) AS porcentaje_asistencia
    FROM alumno a
    INNER JOIN usuario u ON a.id_usuario = u.id_usuario
    INNER JOIN alumno_matricula am ON a.id_alumno = am.id_alumno
    INNER JOIN seccion s ON am.id_seccion = s.id_seccion
    INNER JOIN grado g ON s.id_grado = g.id_grado
    INNER JOIN nivel n ON g.id_nivel = n.id_nivel
    INNER JOIN matricula m ON m.id_matricula = am.id_matricula
    INNER JOIN alumno_matricula_curso amc ON am.id_alumno_matricula = amc.id_alumno_matricula
    LEFT JOIN asistencia a1 ON a1.id_alumno_matricula_curso = amc.id_alumno_matricula_curso
    WHERE amc.id_curso = p_id_curso AND DATE(a1.fecha) = p_fecha 
    ORDER BY u.apellido_paterno ASC, u.apellido_materno ASC, u.nombre ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarAlumnosPorApoderado` (IN `p_id_matricula` INT, IN `p_id_apoderado` INT)   BEGIN
    SELECT 
        am.id_alumno_matricula,
        am.fecha_inscripcion,
        a.id_alumno,
        a.codigo_alumno,
        a.estado AS estado_alumno,
        u.id_usuario AS id_usuario_alumno,
        u.nombre AS nombre_alumno,
        u.apellido_paterno AS apellido_paterno_alumno,
        u.apellido_materno AS apellido_materno_alumno,
        u.sexo AS sexo_alumno,
        u.email AS email_alumno,
        u.telefono AS telefono_alumno,
        u.direccion AS direccion_alumno,
        u.fecha_nacimiento AS fecha_nacimiento_alumno,
        u.tipo_doc AS tipo_doc_alumno,
        u.num_documento AS num_documento_alumno,
        u.url_imagen,
        ap.id_apoderado,
        ap.codigo_apoderado,
        ap.estado AS estado_apoderado,
        s.id_seccion,
        s.nombre AS nombre_seccion,
        s.limite_cupo,
        s.turno,
        g.id_grado,
        g.nombre AS nombre_grado,
        n.id_nivel,
        n.nombre AS nombre_nivel

    FROM alumno_matricula am
    INNER JOIN alumno a ON a.id_alumno = am.id_alumno
    INNER JOIN usuario u ON u.id_usuario = a.id_usuario
    INNER JOIN alumno_apoderado aa ON aa.id_alumno = a.id_alumno
    INNER JOIN apoderado ap ON ap.id_apoderado = aa.id_apoderado
    INNER JOIN seccion s ON s.id_seccion = am.id_seccion
    INNER JOIN grado g ON g.id_grado = s.id_grado
    INNER JOIN nivel n ON n.id_nivel = g.id_nivel
    WHERE am.id_matricula = p_id_matricula AND ap.id_apoderado = p_id_apoderado;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarAlumnosPorCurso` (IN `p_id_curso` INT)   BEGIN
    SELECT 
        a.id_alumno,
        a.id_usuario,
        a.id_institucion,
        a.codigo_alumno,
        a.estado AS estado_alumno,
        am.id_alumno_matricula,
        u.apellido_paterno,
        u.apellido_materno,
        u.nombre,
        u.sexo,
        u.email,
        u.url_imagen,
        u.telefono,
        u.ubigeo,
        u.direccion,
        u.fecha_nacimiento,
        u.tipo_doc,
        u.num_documento,
        u.estado AS estado_usuario,
        am.id_matricula,
        m.nombre_matricula,
        m.anio_academico,
        am.fecha_inscripcion,
        s.id_seccion,
        s.nombre AS nombre_seccion,
        s.limite_cupo,
        s.turno,
        g.id_grado,
        g.nombre AS nombre_grado,
        n.id_nivel,
        n.nombre AS nombre_nivel
    FROM alumno a
    INNER JOIN usuario u ON a.id_usuario = u.id_usuario
    INNER JOIN alumno_matricula am ON a.id_alumno = am.id_alumno
    INNER JOIN seccion s ON am.id_seccion = s.id_seccion
    INNER JOIN grado g ON s.id_grado = g.id_grado
    INNER JOIN nivel n ON g.id_nivel = n.id_nivel
    INNER JOIN matricula m ON m.id_matricula = am.id_matricula
    INNER JOIN alumno_matricula_curso amc ON am.id_alumno_matricula = amc.id_alumno_matricula
    WHERE amc.id_curso = p_id_curso
    ORDER BY u.apellido_paterno ASC, u.apellido_materno ASC, u.nombre ASC;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarAlumnosPorInstitucion` (IN `p_id_institucion` INT, IN `p_id_matricula` INT)   BEGIN
    SELECT 
        a.id_alumno,
        a.id_usuario,
        a.id_institucion,
        a.codigo_alumno,
        a.estado AS estado_alumno,
        u.nombre,
        u.apellido_paterno,
        u.apellido_materno,
        u.sexo,
        u.email,
        u.url_imagen,
        u.telefono,
        u.ubigeo,
        u.direccion,
        u.fecha_nacimiento,
        u.tipo_doc,
        u.num_documento,
        u.estado AS estado_usuario,
        am.id_matricula,
        m.nombre_matricula,
        m.anio_academico,
        am.fecha_inscripcion,
        s.id_seccion,
        s.nombre AS nombre_seccion,
        s.limite_cupo,
        s.turno,
        g.id_grado,
        g.nombre AS nombre_grado,
        n.id_nivel,
        n.nombre AS nombre_nivel
    FROM alumno a
    INNER JOIN usuario u ON a.id_usuario = u.id_usuario
    INNER JOIN alumno_matricula am ON a.id_alumno = am.id_alumno
    INNER JOIN seccion s ON am.id_seccion = s.id_seccion
    INNER JOIN grado g ON s.id_grado = g.id_grado
    INNER JOIN nivel n ON g.id_nivel = n.id_nivel
    INNER JOIN matricula m ON m.id_matricula = am.id_matricula
    WHERE a.id_institucion = p_id_institucion
      AND am.id_matricula = p_id_matricula
    ORDER BY u.apellido_paterno ASC, u.apellido_materno ASC, u.nombre ASC;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarApoderadosPorAlumno` (IN `p_id_alumno` INT)   BEGIN
    SELECT 
        ap.id_apoderado,
        u.nombre,
        u.apellido_paterno,
        u.apellido_materno,
        u.sexo,
        u.email,
        u.telefono,
        u.direccion,
        u.fecha_nacimiento,
        u.tipo_doc,
        u.num_documento,
        u.estado,
        ap.codigo_apoderado,
        ap.estado AS estado_apoderado,
        aa.parentesco
    FROM 
        alumno_apoderado aa
    INNER JOIN 
        apoderado ap ON aa.id_apoderado = ap.id_apoderado
    INNER JOIN 
        usuario u ON ap.id_usuario = u.id_usuario
    WHERE 
        aa.id_alumno = p_id_alumno;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarAsistenciaPorAlumnoCurso` (IN `p_id_alumno_matricula` INT, IN `p_id_curso` INT)   BEGIN
    SELECT
        a.id_asistencia,
        a.fecha,
        a.estado,
        a.observaciones
    FROM asistencia a
    INNER JOIN alumno_matricula_curso amc ON a.id_alumno_matricula_curso = amc.id_alumno_matricula_curso
    INNER JOIN alumno_matricula am ON amc.id_alumno_matricula = am.id_alumno_matricula
    WHERE am.id_alumno_matricula = p_id_alumno_matricula AND amc.id_curso = p_id_curso
    ORDER BY a.fecha DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarCursosPorAlumnoMatricula` (IN `p_id_alumno_matricula` INT)   BEGIN
    SELECT 
        amc.id_alumno_matricula_curso,
        amc.fecha_inscripcion AS fecha_inscripcion_curso,
        am.id_alumno_matricula,
        am.fecha_inscripcion AS fecha_inscripcion_matricula,
        c.id_curso,
        c.nombre AS nombre_curso,
        c.descripcion AS descripcion_curso,
        c.estado AS estado_curso
    FROM alumno_matricula_curso amc
    INNER JOIN alumno_matricula am ON am.id_alumno_matricula = amc.id_alumno_matricula
    INNER JOIN curso c ON c.id_curso = amc.id_curso
    WHERE amc.id_alumno_matricula = p_id_alumno_matricula;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarCursosPorDocente` (IN `docente_id` INT)   BEGIN
    SELECT 
        c.id_curso,
        c.id_grado,
        c.nombre AS nombre_curso,
        c.descripcion,
        c.estado
    FROM 
        curso_docente cd
    INNER JOIN 
        curso c ON cd.id_curso = c.id_curso
    WHERE 
        cd.id_docente = docente_id;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarCursosPorDocenteConDetalle` (IN `docente_id` INT)   BEGIN
    SELECT 
        c.id_curso AS "id_curso",
        c.nombre AS "nombre_curso",
        c.descripcion AS "descripcion_curso",
        c.estado AS "estado_curso",
        g.id_grado AS "id_grado",
        g.nombre AS "nombre_grado",
        n.id_nivel AS "id_nivel",
        n.nombre AS "nombre_nivel",
        i.id_institucion AS "id_institucion",
        i.nombre AS "nombre_institucion",
        GROUP_CONCAT(DISTINCT s.nombre ORDER BY s.nombre SEPARATOR ', ') AS "secciones",
        COUNT(DISTINCT am.id_alumno) AS "numero_alumnos"
    FROM 
        curso_docente cd
    INNER JOIN 
        curso c ON cd.id_curso = c.id_curso
    INNER JOIN 
        grado g ON c.id_grado = g.id_grado
    INNER JOIN 
        nivel n ON g.id_nivel = n.id_nivel
    INNER JOIN 
        institucion i ON n.id_institucion = i.id_institucion
    INNER JOIN 
        seccion s ON s.id_grado = g.id_grado
    LEFT JOIN 
        alumno_matricula am ON am.id_seccion = s.id_seccion AND am.id_alumno_matricula IN (
            SELECT id_alumno_matricula
            FROM alumno_matricula_curso
            WHERE id_curso = c.id_curso
        )
    WHERE 
        cd.id_docente = docente_id
    GROUP BY 
        c.id_curso, c.nombre, c.descripcion, c.estado, g.id_grado, g.nombre, n.id_nivel, n.nombre, i.id_institucion, i.nombre
    ORDER BY 
        i.nombre, n.nombre, g.nombre, c.nombre;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarDocentesPorInstitucion` (IN `p_id_institucion` INT)   BEGIN
    SELECT 
        d.id_docente,
        d.id_usuario,
        d.id_institucion,
        u.nombre,
        u.apellido_paterno,
        u.apellido_materno,
        u.sexo,
        u.email,
        u.url_imagen,
        u.telefono,
        u.ubigeo,
        u.direccion,
        u.fecha_nacimiento,
        u.tipo_doc,
        u.num_documento,
        d.codigo_docente,
        d.especialidad,
        d.estado
    FROM 
        docente d
    INNER JOIN 
        usuario u ON d.id_usuario = u.id_usuario
    WHERE 
        d.id_institucion = p_id_institucion;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarEtapasPorAlumnoCurso` (IN `p_id_alumno_matricula` INT, IN `p_id_curso` INT)   BEGIN
    SELECT DISTINCT 
        es.id_etapa,
        es.nombre AS nombre_etapa,
        es.fecha_inicio,
        es.fecha_fin
    FROM nota_alumno_curso nac
    INNER JOIN alumno_matricula_curso amc ON nac.id_alumno_matricula_curso = amc.id_alumno_matricula_curso
    INNER JOIN nota n ON nac.id_nota = n.id_nota
    INNER JOIN etapa_escolar es ON n.id_etapa_escolar = es.id_etapa
    INNER JOIN alumno_matricula am ON amc.id_alumno_matricula = am.id_alumno_matricula
    WHERE amc.id_curso = p_id_curso 
      AND amc.id_alumno_matricula = p_id_alumno_matricula;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarMatriculas` (IN `p_id_institucion` INT)   BEGIN
    SELECT 
        id_matricula,
        nombre_matricula,
        anio_academico
    FROM 
        matricula
    WHERE 
        id_institucion = p_id_institucion
    ORDER BY 
        anio_academico DESC;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ListarNotasPorCursoAlumnoEtapa` (IN `p_id_alumno_matricula` INT, IN `p_id_curso` INT, IN `p_id_etapa_escolar` INT)   BEGIN
    SELECT 
        nac.id_nota_alumno_curso,
        n.nombre,
        n.peso,
        nac.nota_obtenida,
        nac.fecha
    FROM nota_alumno_curso nac
    INNER JOIN alumno_matricula_curso amc ON nac.id_alumno_matricula_curso = amc.id_alumno_matricula_curso
    INNER JOIN nota n ON nac.id_nota = n.id_nota
    INNER JOIN alumno_matricula am ON amc.id_alumno_matricula = am.id_alumno_matricula
    WHERE am.id_alumno_matricula = p_id_alumno_matricula 
      AND amc.id_curso = p_id_curso 
      AND n.id_etapa_escolar = p_id_etapa_escolar;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ModificarAlumno` (IN `p_id_usuario` INT, IN `p_nombre` VARCHAR(255), IN `p_apellido_paterno` VARCHAR(255), IN `p_apellido_materno` VARCHAR(255), IN `p_sexo` ENUM('Masculino','Femenino'), IN `p_email` VARCHAR(255), IN `p_url_imagen` VARCHAR(255), IN `p_telefono` VARCHAR(20), IN `p_ubigeo` VARCHAR(6), IN `p_direccion` VARCHAR(255), IN `p_fecha_nacimiento` DATE, IN `p_tipo_doc` ENUM('DNI','Carne de extranjería','Pasaporte'), IN `p_num_documento` VARCHAR(15), IN `p_id_institucion` INT, IN `p_id_matricula` INT, IN `p_id_seccion` INT)   BEGIN
    DECLARE alumno_id INT;

    -- Validar si el usuario existe
    IF NOT EXISTS (
        SELECT 1 
        FROM usuario 
        WHERE id_usuario = p_id_usuario
    ) THEN
        SELECT 'FAILED_USER_NOT_FOUND' AS mensaje;
    
    -- Validar si el email ya está en uso por otro usuario
    ELSEIF EXISTS (
        SELECT 1 
        FROM usuario 
        WHERE email = p_email AND id_usuario != p_id_usuario
    ) THEN
        SELECT 'FAILED_EMAIL' AS mensaje;

    -- Validar si el documento ya está en uso por otro usuario
    ELSEIF EXISTS (
        SELECT 1 
        FROM usuario 
        WHERE tipo_doc = p_tipo_doc AND num_documento = p_num_documento AND id_usuario != p_id_usuario
    ) THEN
        SELECT 'FAILED_DOC' AS mensaje;

    ELSE
        -- Actualizar datos del usuario
        UPDATE usuario
        SET 
            nombre = p_nombre,
            apellido_paterno = p_apellido_paterno,
            apellido_materno = p_apellido_materno,
            sexo = p_sexo,
            email = p_email,
            url_imagen = IFNULL(p_url_imagen, 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default'),
            telefono = p_telefono,
            ubigeo = p_ubigeo,
            direccion = p_direccion,
            fecha_nacimiento = p_fecha_nacimiento,
            tipo_doc = p_tipo_doc,
            num_documento = p_num_documento
        WHERE id_usuario = p_id_usuario;

        -- Obtener el ID del alumno correspondiente al usuario
        SELECT id_alumno INTO alumno_id 
        FROM alumno 
        WHERE id_usuario = p_id_usuario;

        -- Validar si el alumno existe
        IF alumno_id IS NULL THEN
            SELECT 'FAILED_ALUMNO_NOT_FOUND' AS mensaje;
        ELSE
            -- Actualizar datos en la tabla alumno
            UPDATE alumno
            SET 
                id_institucion = p_id_institucion
            WHERE id_usuario = p_id_usuario;

            -- Actualizar datos en la tabla alumno_matricula
            UPDATE alumno_matricula
            SET 
                id_matricula = p_id_matricula,
                id_seccion = p_id_seccion,
                fecha_inscripcion = CURDATE()
            WHERE id_alumno = alumno_id;

            -- Devolver éxito
            SELECT 'SUCCESS' AS mensaje, p_id_usuario AS id_usuario, alumno_id AS id_alumno;
        END IF;
    END IF;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ModificarAsistencia` (IN `p_id_asistencia` INT, IN `p_estado` ENUM('PRESENTE','AUSENTE','TARDANZA','JUSTIFICADO'), IN `p_observaciones` TEXT)   BEGIN
    UPDATE asistencia
    SET
        estado = p_estado,
        observaciones = p_observaciones
    WHERE id_asistencia = p_id_asistencia;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ModificarDocente` (IN `p_id_docente` INT, IN `p_nombre` VARCHAR(255), IN `p_apellido_paterno` VARCHAR(255), IN `p_apellido_materno` VARCHAR(255), IN `p_sexo` ENUM('Masculino','Femenino'), IN `p_email` VARCHAR(255), IN `p_url_imagen` VARCHAR(255), IN `p_telefono` VARCHAR(20), IN `p_ubigeo` VARCHAR(6), IN `p_direccion` VARCHAR(255), IN `p_fecha_nacimiento` DATE, IN `p_tipo_doc` ENUM('DNI','Carne de extranjería','Pasaporte'), IN `p_num_documento` VARCHAR(15), IN `p_especialidad` VARCHAR(255))   BEGIN
    DECLARE v_id_usuario INT;

    SELECT id_usuario INTO v_id_usuario
    FROM docente
    WHERE id_docente = p_id_docente;

    IF v_id_usuario IS NULL THEN
        SELECT 'FAILED_NOT_FOUND' AS mensaje;
    ELSE
        IF EXISTS (
            SELECT 1
            FROM usuario
            WHERE email = p_email
              AND id_usuario != v_id_usuario
        ) THEN
            SELECT 'FAILED_EMAIL' AS mensaje;

        -- Verificar conflicto con documento
        ELSEIF EXISTS (
            SELECT 1
            FROM usuario
            WHERE tipo_doc = p_tipo_doc
              AND num_documento = p_num_documento
              AND id_usuario != v_id_usuario
        ) THEN
            SELECT 'FAILED_DOC' AS mensaje;

        ELSE
            UPDATE usuario
            SET
                nombre = p_nombre,
                apellido_paterno = p_apellido_paterno,
                apellido_materno = p_apellido_materno,
                sexo = p_sexo,
                email = p_email,
                url_imagen = IFNULL(p_url_imagen, 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default'),
                telefono = p_telefono,
                ubigeo = p_ubigeo,
                direccion = p_direccion,
                fecha_nacimiento = p_fecha_nacimiento,
                tipo_doc = p_tipo_doc,
                num_documento = p_num_documento
            WHERE id_usuario = v_id_usuario;

            UPDATE docente
            SET
                especialidad = p_especialidad
            WHERE id_docente = p_id_docente;

            SELECT 'SUCCESS' AS mensaje;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ModificarNotas` (IN `p_id_nota_alumno_curso` INT, IN `p_nota_obtenida` DECIMAL(5,2))   BEGIN
    UPDATE nota_alumno_curso
    SET 
        nota_obtenida = p_nota_obtenida,
        fecha = CURDATE()
    WHERE 
        id_nota_alumno_curso = p_id_nota_alumno_curso;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `ObtenerEntidadesPorDNI` (IN `dni_usuario` VARCHAR(15))   BEGIN
    CREATE TEMPORARY TABLE tmp_resultado (
        id INT,
        id_institucion INT,
        codigo VARCHAR(50),
        rol VARCHAR(20), -- Nueva columna para el rol
        nombre_ie VARCHAR(255), -- Nombre de la institución
        url_imagen_ie VARCHAR(255) -- URL de la imagen de la institución
    );

    -- Insertar registros de alumnos
    INSERT INTO tmp_resultado (id, id_institucion, codigo, rol, nombre_ie, url_imagen_ie)
    SELECT 
        a.id_alumno, 
        a.id_institucion, 
        a.codigo_alumno, 
        'Alumno',
        i.nombre,
        i.url_imagen
    FROM alumno a
    JOIN usuario u ON a.id_usuario = u.id_usuario
    JOIN institucion i ON a.id_institucion = i.id_institucion
    WHERE u.num_documento = dni_usuario;

    -- Insertar registros de docentes
    INSERT INTO tmp_resultado (id, id_institucion, codigo, rol, nombre_ie, url_imagen_ie)
    SELECT 
        d.id_docente, 
        d.id_institucion, 
        d.codigo_docente, 
        'Docente',
        i.nombre,
        i.url_imagen
    FROM docente d
    JOIN usuario u ON d.id_usuario = u.id_usuario
    JOIN institucion i ON d.id_institucion = i.id_institucion
    WHERE u.num_documento = dni_usuario;

    -- Insertar registros de coordinadores
    INSERT INTO tmp_resultado (id, id_institucion, codigo, rol, nombre_ie, url_imagen_ie)
    SELECT 
        c.id_coordinador, 
        c.id_institucion, 
        c.codigo_coordinador, 
        'Coordinador',
        i.nombre,
        i.url_imagen
    FROM coordinador c
    JOIN usuario u ON c.id_usuario = u.id_usuario
    JOIN institucion i ON c.id_institucion = i.id_institucion
    WHERE u.num_documento = dni_usuario;

    -- Insertar registros de apoderados
    INSERT INTO tmp_resultado (id, id_institucion, codigo, rol, nombre_ie, url_imagen_ie)
    SELECT 
        ap.id_apoderado, 
        ap.id_institucion, 
        ap.codigo_apoderado, 
        'Apoderado',
        i.nombre,
        i.url_imagen
    FROM apoderado ap
    JOIN usuario u ON ap.id_usuario = u.id_usuario
    JOIN institucion i ON ap.id_institucion = i.id_institucion
    WHERE u.num_documento = dni_usuario;

    -- Seleccionar todos los registros de la tabla temporal
    SELECT * FROM tmp_resultado;

    -- Eliminar la tabla temporal
    DROP TEMPORARY TABLE tmp_resultado;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ObtenerNivelesGradosSecciones` (IN `p_id_institucion` INT)   BEGIN
    SELECT 
        n.id_nivel,
        n.nombre AS nombre_nivel,
        g.id_grado,
        g.nombre AS nombre_grado,
        s.id_seccion,
        s.nombre AS nombre_seccion,
        s.limite_cupo,
        s.turno
    FROM seccion s 
    INNER JOIN grado g ON s.id_grado = g.id_grado
    INNER JOIN nivel n ON g.id_nivel = n.id_nivel
    WHERE n.id_institucion = p_id_institucion;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `RegistrarAlumno` (IN `p_nombre` VARCHAR(255), IN `p_apellido_paterno` VARCHAR(255), IN `p_apellido_materno` VARCHAR(255), IN `p_sexo` ENUM('Masculino','Femenino'), IN `p_email` VARCHAR(255), IN `p_url_imagen` VARCHAR(255), IN `p_telefono` VARCHAR(20), IN `p_ubigeo` VARCHAR(6), IN `p_direccion` VARCHAR(255), IN `p_fecha_nacimiento` DATE, IN `p_tipo_doc` ENUM('DNI','Carne de extranjería','Pasaporte'), IN `p_num_documento` VARCHAR(15), IN `p_id_institucion` INT, IN `p_id_matricula` INT, IN `p_id_seccion` INT)   BEGIN
    DECLARE new_user_id INT;
    DECLARE new_alumno_id INT;
    DECLARE codigo_alumno VARCHAR(50);

    -- Validar si el email ya existe
    IF EXISTS (
        SELECT 1
        FROM usuario
        WHERE email = p_email
    ) THEN
        SELECT 'FAILED_EMAIL' AS mensaje;
        
    -- Validar si el documento ya existe
    ELSEIF EXISTS (
        SELECT 1
        FROM usuario
        WHERE tipo_doc = p_tipo_doc AND num_documento = p_num_documento
    ) THEN
        SELECT 'FAILED_DOC' AS mensaje;
        
    ELSE
        -- Insertar en la tabla usuario
        INSERT INTO usuario (
            nombre,
            apellido_paterno,
            apellido_materno,
            sexo,
            email,
            password,
            url_imagen,
            telefono,
            ubigeo,
            direccion,
            fecha_nacimiento,
            tipo_doc,
            num_documento,
            estado
        )
        VALUES (
            p_nombre,
            p_apellido_paterno,
            p_apellido_materno,
            p_sexo,
            p_email,
            p_num_documento, -- La contraseña es igual al número de documento
            IFNULL(p_url_imagen, 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default'),
            p_telefono,
            p_ubigeo,
            p_direccion,
            p_fecha_nacimiento,
            p_tipo_doc,
            p_num_documento,
            'active'
        );
        
        SET new_user_id = LAST_INSERT_ID();

        -- Generar código de alumno (ej. 00001-S-12345678)
        SET codigo_alumno = CONCAT(LPAD(p_id_institucion, 5, '0'), '-S-', p_num_documento);

        -- Insertar en la tabla alumno
        INSERT INTO alumno (
            id_usuario,
            id_institucion,
            codigo_alumno,
            estado
        )
        VALUES (
            new_user_id,
            p_id_institucion,
            codigo_alumno,
            'Activo'
        );

        SET new_alumno_id = LAST_INSERT_ID();

        -- Insertar en la tabla alumno_matricula
        INSERT INTO alumno_matricula (
            id_alumno,
            id_matricula,
            id_seccion,
            fecha_inscripcion
        )
        VALUES (
            new_alumno_id,
            p_id_matricula,
            p_id_seccion,
            CURDATE()
        );

        -- Devolver éxito
        SELECT 'SUCCESS' AS mensaje, new_user_id AS id_usuario, new_alumno_id AS id_alumno;
    END IF;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `RegistrarAlumnoUserExist` (IN `p_id_usuario` INT, IN `p_id_institucion` INT, IN `p_id_matricula` INT, IN `p_id_seccion` INT)   BEGIN
    DECLARE new_alumno_id INT;
    DECLARE codigo_alumno VARCHAR(50);
    DECLARE v_num_documento VARCHAR(15);

    SELECT num_documento 
    INTO v_num_documento
    FROM usuario
    WHERE id_usuario = p_id_usuario;

    IF v_num_documento IS NULL THEN
        SELECT 'FAILED_USER_NOT_FOUND' AS mensaje;
    ELSE
        SET codigo_alumno = CONCAT(LPAD(p_id_institucion, 5, '0'), '-S-', v_num_documento);

        SELECT id_alumno
        INTO new_alumno_id
        FROM alumno
        WHERE id_usuario = p_id_usuario 
          AND id_institucion = p_id_institucion 
          AND codigo_alumno = codigo_alumno;

        IF new_alumno_id IS NULL THEN
            INSERT INTO alumno (
                id_usuario,
                id_institucion,
                codigo_alumno,
                estado
            )
            VALUES (
                p_id_usuario,
                p_id_institucion,
                codigo_alumno,
                'Activo'
            );

            SET new_alumno_id = LAST_INSERT_ID();
        END IF;

        IF EXISTS (
            SELECT 1
            FROM alumno_matricula
            WHERE id_alumno = new_alumno_id
              AND id_matricula = p_id_matricula
              AND id_seccion = p_id_seccion
        ) THEN
            SELECT 'FAILED_ALUM_MATIRC_EXIST' AS mensaje;
        ELSE
            INSERT INTO alumno_matricula (
                id_alumno,
                id_matricula,
                id_seccion,
                fecha_inscripcion
            )
            VALUES (
                new_alumno_id,
                p_id_matricula,
                p_id_seccion,
                CURDATE()
            );

            SELECT 'SUCCESS' AS mensaje, p_id_usuario AS id_usuario, new_alumno_id AS id_alumno;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `RegistrarApoderado` (IN `p_nombre` VARCHAR(255), IN `p_apellido_paterno` VARCHAR(255), IN `p_apellido_materno` VARCHAR(255), IN `p_sexo` ENUM('Masculino','Femenino'), IN `p_email` VARCHAR(255), IN `p_url_imagen` VARCHAR(255), IN `p_telefono` VARCHAR(20), IN `p_ubigeo` VARCHAR(6), IN `p_direccion` VARCHAR(255), IN `p_fecha_nacimiento` DATE, IN `p_tipo_doc` ENUM('DNI','Carne de extranjería','Pasaporte'), IN `p_num_documento` VARCHAR(15), IN `p_id_institucion` INT, IN `p_id_alumno` INT, IN `p_parentesco` ENUM('Padre','Madre','Tutor','Otro'))   BEGIN
    DECLARE new_user_id INT;
    DECLARE new_apoderado_id INT;
    DECLARE codigo_apoderado VARCHAR(50);

    IF EXISTS (
        SELECT 1
        FROM usuario
        WHERE email = p_email
    ) THEN
        SELECT 'FAILED_EMAIL' AS mensaje;
        
    -- Validar si el documento ya existe
    ELSEIF EXISTS (
        SELECT 1
        FROM usuario
        WHERE tipo_doc = p_tipo_doc AND num_documento = p_num_documento
    ) THEN
        SELECT 'FAILED_DOC' AS mensaje;
        
    ELSE
        INSERT INTO usuario (
            nombre,
            apellido_paterno,
            apellido_materno,
            sexo,
            email,
            password,
            url_imagen,
            telefono,
            ubigeo,
            direccion,
            fecha_nacimiento,
            tipo_doc,
            num_documento,
            estado
        )
        VALUES (
            p_nombre,
            p_apellido_paterno,
            p_apellido_materno,
            p_sexo,
            p_email,
            p_num_documento,
            IFNULL(p_url_imagen, 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default'),
            p_telefono,
            p_ubigeo,
            p_direccion,
            p_fecha_nacimiento,
            p_tipo_doc,
            p_num_documento,
            'active'
        );

        SET new_user_id = LAST_INSERT_ID();

        SET codigo_apoderado = CONCAT(LPAD(p_id_institucion, 5, '0'), '-A-', p_num_documento);

        INSERT INTO apoderado (
            id_usuario,
            id_institucion,
            codigo_apoderado,
            estado
        )
        VALUES (
            new_user_id,
            p_id_institucion,
            codigo_apoderado,
            'Activo'
        );

        SET new_apoderado_id = LAST_INSERT_ID();

        INSERT INTO alumno_apoderado (
            id_alumno,
            id_apoderado,
            id_institucion,
            parentesco
        )
        VALUES (
            p_id_alumno,
            new_apoderado_id,
            p_id_institucion,
            p_parentesco
        );

        SELECT 'SUCCESS' AS mensaje, new_user_id AS id_usuario, new_apoderado_id AS id_apoderado;
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `RegistrarApoderadoUserExist` (IN `p_id_usuario` INT, IN `p_id_institucion` INT, IN `p_id_alumno` INT, IN `p_parentesco` ENUM('Padre','Madre','Tutor','Otro'))   BEGIN
    DECLARE new_apoderado_id INT;
    DECLARE codigo_apoderado VARCHAR(50);

    IF EXISTS (
        SELECT 1
        FROM apoderado
        WHERE id_usuario = p_id_usuario
    ) THEN
        SELECT id_apoderado INTO new_apoderado_id
        FROM apoderado
        WHERE id_usuario = p_id_usuario;

    ELSE
        SET codigo_apoderado = CONCAT(LPAD(p_id_institucion, 5, '0'), '-A-', p_id_usuario);

        INSERT INTO apoderado (
            id_usuario,
            id_institucion,
            codigo_apoderado,
            estado
        )
        VALUES (
            p_id_usuario,
            p_id_institucion,
            codigo_apoderado,
            'Activo'
        );

        SET new_apoderado_id = LAST_INSERT_ID();
    END IF;

    INSERT INTO alumno_apoderado (
        id_alumno,
        id_apoderado,
        id_institucion,
        parentesco
    )
    VALUES (
        p_id_alumno,
        new_apoderado_id,
        p_id_institucion,
        p_parentesco
    );

    SELECT 'SUCCESS' AS mensaje, new_apoderado_id AS id_apoderado;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `RegistrarAsistenciaPorCurso` (IN `p_id_curso` INT, IN `p_fecha` DATETIME)   BEGIN
    INSERT INTO asistencia (id_alumno_matricula_curso, fecha, estado)
    SELECT 
        amc.id_alumno_matricula_curso, 
        p_fecha, 
        'PENDIENTE'
    FROM alumno_matricula_curso amc
    INNER JOIN alumno_matricula am ON amc.id_alumno_matricula = am.id_alumno_matricula
    WHERE amc.id_curso = p_id_curso;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `RegistrarDocente` (IN `p_nombre` VARCHAR(255), IN `p_apellido_paterno` VARCHAR(255), IN `p_apellido_materno` VARCHAR(255), IN `p_sexo` ENUM('Masculino','Femenino'), IN `p_email` VARCHAR(255), IN `p_url_imagen` VARCHAR(255), IN `p_telefono` VARCHAR(20), IN `p_ubigeo` VARCHAR(6), IN `p_direccion` VARCHAR(255), IN `p_fecha_nacimiento` DATE, IN `p_tipo_doc` ENUM('DNI','Carne de extranjería','Pasaporte'), IN `p_num_documento` VARCHAR(15), IN `p_id_institucion` INT, IN `p_especialidad` VARCHAR(255))   BEGIN
    DECLARE new_user_id INT;
    DECLARE new_docente_id INT;
    DECLARE codigo_docente VARCHAR(50);

    IF EXISTS (
        SELECT 1 FROM usuario WHERE email = p_email
    ) THEN
        SELECT 'FAILED_EMAIL' AS mensaje;
        
    ELSEIF EXISTS (
        SELECT 1 FROM usuario WHERE tipo_doc = p_tipo_doc AND num_documento = p_num_documento
    ) THEN
        SELECT 'FAILED_DOC' AS mensaje;
        
    ELSE
        INSERT INTO usuario (
            nombre,
            apellido_paterno,
            apellido_materno,
            sexo,
            email,
            password,
            url_imagen,
            telefono,
            ubigeo,
            direccion,
            fecha_nacimiento,
            tipo_doc,
            num_documento,
            estado
        )
        VALUES (
            p_nombre,
            p_apellido_paterno,
            p_apellido_materno,
            p_sexo,
            p_email,
            p_num_documento,
            IFNULL(p_url_imagen, 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default'),
            p_telefono,
            p_ubigeo,
            p_direccion,
            p_fecha_nacimiento,
            p_tipo_doc,
            p_num_documento,
            'active'
        );

        SET new_user_id = LAST_INSERT_ID();

        SET codigo_docente = CONCAT(LPAD(p_id_institucion, 5, '0'), '-T-', p_num_documento);

        INSERT INTO docente (
            id_usuario,
            id_institucion,
            codigo_docente,
            especialidad,
            estado
        )
        VALUES (
            new_user_id,
            p_id_institucion,
            codigo_docente,
            p_especialidad,
            'Activo'
        );

        SET new_docente_id = LAST_INSERT_ID();

        SELECT 'SUCCESS' AS mensaje, new_user_id AS id_usuario, new_docente_id AS id_docente;
    END IF;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `RegistrarDocenteUserExist` (IN `p_id_usuario` INT, IN `p_id_institucion` INT, IN `p_especialidad` VARCHAR(255))   BEGIN
    DECLARE new_docente_id INT;
    DECLARE codigo_docente VARCHAR(50);
    DECLARE num_documento_usuario VARCHAR(50);

    SELECT num_documento INTO num_documento_usuario
    FROM usuario
    WHERE id_usuario = p_id_usuario
    LIMIT 1;

    IF EXISTS (
        SELECT 1 FROM docente WHERE id_usuario = p_id_usuario
    ) THEN
        SELECT id_docente INTO new_docente_id
        FROM docente
        WHERE id_usuario = p_id_usuario;

    ELSE
        SET codigo_docente = CONCAT(LPAD(p_id_institucion, 5, '0'), '-T-', num_documento_usuario);

        INSERT INTO docente (
            id_usuario,
            id_institucion,
            codigo_docente,
            especialidad,
            estado
        )
        VALUES (
            p_id_usuario,
            p_id_institucion,
            codigo_docente,
            p_especialidad,
            'Activo'
        );

        SET new_docente_id = LAST_INSERT_ID();
    END IF;

    -- Retornar resultado
    SELECT 'SUCCESS' AS mensaje, new_docente_id AS id_docente;
END$$

CREATE DEFINER=`error`@`%` PROCEDURE `RegistrarUsuario` (IN `p_nombre` VARCHAR(255), IN `p_apellido_paterno` VARCHAR(255), IN `p_apellido_materno` VARCHAR(255), IN `p_sexo` ENUM('Masculino','Femenino'), IN `p_email` VARCHAR(255), IN `p_password` VARCHAR(255), IN `p_url_imagen` VARCHAR(255), IN `p_telefono` VARCHAR(20), IN `p_ubigeo` VARCHAR(6), IN `p_direccion` VARCHAR(255), IN `p_fecha_nacimiento` DATE, IN `p_tipo_doc` ENUM('DNI','Carne de extranjería','Pasaporte'), IN `p_num_documento` VARCHAR(15))   BEGIN
    -- Verificar si el email ya existe
    IF EXISTS (
        SELECT 1
        FROM usuario
        WHERE email = p_email
    ) THEN
        SELECT 'FAILED_EMAIL' AS mensaje;
    -- Verificar si el tipo de documento y número de documento ya están registrados
    ELSEIF EXISTS (
        SELECT 1
        FROM usuario
        WHERE tipo_doc = p_tipo_doc AND num_documento = p_num_documento
    ) THEN
        SELECT 'FAILED_DOC' AS mensaje;
    ELSE
        -- Insertar el nuevo usuario
        INSERT INTO usuario (
            nombre,
            apellido_paterno,
            apellido_materno,
            sexo,
            email,
            password,
            url_imagen,
            telefono,
            ubigeo,
            direccion,
            fecha_nacimiento,
            tipo_doc,
            num_documento,
            estado
        )
        VALUES (
            p_nombre,
            p_apellido_paterno,
            p_apellido_materno,
            p_sexo,
            p_email,
            p_password,
            IFNULL(p_url_imagen, 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default'),
            p_telefono,
            p_ubigeo,
            p_direccion,
            p_fecha_nacimiento,
            p_tipo_doc,
            p_num_documento,
            'active'
        );
        SELECT 'SUCCESS' AS mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ToggleEstadoAlumno` (IN `p_id_alumno` INT)   BEGIN
    -- Verificar si el alumno existe
    IF EXISTS (SELECT 1 FROM alumno WHERE id_alumno = p_id_alumno) THEN
        -- Actualizar el estado alternando entre 'Activo' e 'Inactivo'
        UPDATE alumno
        SET estado = CASE 
                        WHEN estado = 'Activo' THEN 'Inactivo'
                        ELSE 'Activo'
                     END
        WHERE id_alumno = p_id_alumno;

        -- Mostrar mensaje de éxito
        SELECT 'SUCCESS' AS status, 
               CONCAT('El estado del alumno ha sido cambiado a ', 
                      (SELECT estado FROM alumno WHERE id_alumno = p_id_alumno), 
                      '.') AS message;
    ELSE
        -- Mostrar mensaje de error si no se encuentra el alumno
        SELECT 'FAILED' AS status, 
               'No se encontró un alumno con el ID proporcionado.' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ToggleEstadoApoderado` (IN `p_id_apoderado` INT)   BEGIN
    IF EXISTS (SELECT 1 FROM apoderado WHERE id_apoderado = p_id_apoderado) THEN
        UPDATE apoderado
        SET estado = CASE 
                        WHEN estado = 'Activo' THEN 'Inactivo'
                        ELSE 'Activo'
                     END
        WHERE id_apoderado = p_id_apoderado;

        SELECT 'SUCCESS' AS status, 
               CONCAT('El estado del apoderado ha sido cambiado a ', 
                      (SELECT estado FROM apoderado WHERE id_apoderado = p_id_apoderado), 
                      '.') AS message;
    ELSE
        SELECT 'FAILED' AS status, 
               'No se encontró un apoderado con el ID proporcionado.' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ToggleEstadoDocente` (IN `p_id_docente` INT)   BEGIN
    IF EXISTS (SELECT 1 FROM docente WHERE id_docente = p_id_docente) THEN
        UPDATE docente
        SET estado = CASE 
                        WHEN estado = 'Activo' THEN 'Inactivo'
                        ELSE 'Activo'
                     END
        WHERE id_docente = p_id_docente;

        SELECT 'SUCCESS' AS status, 
               CONCAT('El estado del docente ha sido cambiado a ', 
                      (SELECT estado FROM docente WHERE id_docente = p_id_docente), 
                      '.') AS message;
    ELSE
        SELECT 'FAILED' AS status, 
               'No se encontró un docente con el ID proporcionado.' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ValidarToken` (IN `p_token` VARCHAR(255))   BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_email VARCHAR(255);
    DECLARE v_num_documento VARCHAR(15);
    DECLARE v_count INT;

    SELECT COUNT(*)
    INTO v_count
    FROM tokensesion
    WHERE token = p_token;

    IF v_count = 0 THEN
        SELECT 'LOGOUT' AS msj;
    ELSE
        SELECT id_usuario
        INTO v_id_usuario
        FROM tokensesion
        WHERE token = p_token;

        UPDATE tokensesion
        SET fecha_creacion = NOW()
        WHERE token = p_token;

        SELECT 
            id_usuario, 
            email, 
            num_documento
        INTO 
            v_id_usuario, 
            v_email, 
            v_num_documento
        FROM usuario
        WHERE id_usuario = v_id_usuario;

        SELECT 
            v_id_usuario AS id_usuario,
            v_email AS email,
            v_num_documento AS num_documento;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ValidarUsuarioCredenciales` (IN `p_email` VARCHAR(255), IN `p_password` VARCHAR(255))   BEGIN
    DECLARE userID INT DEFAULT 0;
    DECLARE sessionToken VARCHAR(255);
    DECLARE userDocument VARCHAR(15);
    DECLARE userNombre VARCHAR(50);
    DECLARE userApellPaterno VARCHAR(50);
    DECLARE userApellMaterno VARCHAR(50);
    DECLARE urlImgPerfil VARCHAR(250);

    SELECT id_usuario, num_documento, nombre, apellido_paterno, apellido_materno, url_imagen INTO userID, userDocument, userNombre, userApellPaterno, userApellMaterno, urlImgPerfil
    FROM Usuario
    WHERE email = p_email AND password = p_password AND estado = 'active'
    LIMIT 1;

    IF userID <> 0 THEN
        DELETE FROM TokenSesion
        WHERE id_usuario = userID;

        REPEAT
            SET sessionToken = UUID();
        UNTIL NOT EXISTS (
            SELECT 1 FROM TokenSesion WHERE token = sessionToken
        ) END REPEAT;

        INSERT INTO TokenSesion (id_usuario, token, fecha_creacion)
        VALUES (userID, sessionToken, NOW());

        SELECT 
        userDocument AS num_documento, 
        sessionToken AS token, 
        userNombre AS nombre, 
        userApellPaterno AS ApellPaterno, 
        userApellMaterno AS ApellMaterno, 
        urlImgPerfil AS imgPerfil;
    ELSE
        SELECT '0' AS resultado;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `VerificarUsuario` (IN `p_tipo_doc` ENUM('DNI','Carne de extranjería','Pasaporte'), IN `p_num_documento` VARCHAR(15))   BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_nombre VARCHAR(255);
    DECLARE v_apellido_paterno VARCHAR(255);
    DECLARE v_apellido_materno VARCHAR(255);
    DECLARE v_sexo ENUM('Masculino','Femenino');
    DECLARE v_email VARCHAR(255);
    DECLARE v_url_imagen VARCHAR(255);
    DECLARE v_telefono VARCHAR(20);
    DECLARE v_ubigeo VARCHAR(6);
    DECLARE v_direccion VARCHAR(255);
    DECLARE v_fecha_nacimiento DATE;
    DECLARE v_estado VARCHAR(20);
    DECLARE v_exist INT DEFAULT 0;
    
    -- Verificar existencia del usuario
    SELECT id_usuario, nombre, apellido_paterno, apellido_materno, sexo, email, url_imagen,
           telefono, ubigeo, direccion, fecha_nacimiento, estado
    INTO v_id_usuario, v_nombre, v_apellido_paterno, v_apellido_materno, v_sexo, v_email, v_url_imagen,
         v_telefono, v_ubigeo, v_direccion, v_fecha_nacimiento, v_estado
    FROM usuario
    WHERE tipo_doc = p_tipo_doc AND num_documento = p_num_documento
    LIMIT 1;
    
    -- Validar si se encontró un usuario
    IF v_id_usuario IS NOT NULL THEN
        SELECT 'SUCCESS' AS status, v_id_usuario AS id, v_nombre AS nombre, v_apellido_paterno AS apellido_paterno,
               v_apellido_materno AS apellido_materno, v_sexo AS sexo, v_email AS email,
               v_url_imagen AS url_imagen, v_telefono AS telefono, v_ubigeo AS ubigeo,
               v_direccion AS direccion, v_fecha_nacimiento AS fecha_nacimiento,
               v_estado AS estado;
    ELSE
        SELECT 'FAILED' AS status, 'El usuario no existe con el tipo y número de documento proporcionados.' AS mensaje;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alumno`
--

CREATE TABLE `alumno` (
  `id_alumno` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_institucion` int(11) NOT NULL,
  `codigo_alumno` varchar(50) NOT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `alumno`
--

INSERT INTO `alumno` (`id_alumno`, `id_usuario`, `id_institucion`, `codigo_alumno`, `estado`) VALUES
(1, 1, 1, '00001-S-12345678', 'Activo'),
(2, 2, 1, '00001-S-87654321', 'Activo'),
(3, 4, 1, '00001-S-71806587', 'Activo'),
(4, 52, 1, '00001-S-1243343', 'Activo'),
(5, 53, 1, '00001-S-98765432', 'Inactivo'),
(6, 54, 1, '00001-S-43206788', 'Inactivo'),
(7, 55, 1, '00001-S-23456789', 'Activo'),
(8, 56, 1, '00001-S-34567890', 'Activo'),
(9, 57, 1, '00001-S-45678901', 'Activo'),
(10, 58, 1, '00001-S-56789012', 'Activo'),
(11, 59, 1, '00001-S-67890123', 'Activo'),
(12, 60, 1, '00001-S-78901234', 'Activo'),
(13, 61, 1, '00001-S-89012345', 'Activo'),
(14, 62, 1, '00001-S-68542685', 'Activo'),
(15, 63, 1, '00001-S-64554587', 'Activo'),
(16, 64, 1, '00001-S-19564872', 'Activo'),
(17, 65, 1, '00001-S-91843923', 'Activo'),
(18, 71, 1, '00001-S-71715050', 'Activo'),
(19, 72, 1, '00001-S-71715051', 'Activo'),
(20, 73, 1, '00001-S-71715252', 'Activo'),
(21, 74, 1, '00001-S-71500089', 'Activo'),
(22, 75, 1, '00001-S-71715174', 'Activo'),
(23, 76, 1, '00001-S-71715176', 'Activo'),
(24, 77, 1, '00001-S-71715074', 'Activo'),
(25, 49, 1, '00001-S-71500070', 'Activo'),
(26, 78, 1, '00001-S-72724545', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alumno_apoderado`
--

CREATE TABLE `alumno_apoderado` (
  `id_alumno_apoderado` int(11) NOT NULL,
  `id_alumno` int(11) NOT NULL,
  `id_apoderado` int(11) NOT NULL,
  `id_institucion` int(11) NOT NULL,
  `parentesco` enum('Padre','Madre','Tutor','Otro') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `alumno_apoderado`
--

INSERT INTO `alumno_apoderado` (`id_alumno_apoderado`, `id_alumno`, `id_apoderado`, `id_institucion`, `parentesco`) VALUES
(1, 3, 1, 1, 'Padre'),
(2, 16, 1, 1, 'Tutor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alumno_matricula`
--

CREATE TABLE `alumno_matricula` (
  `id_alumno_matricula` int(11) NOT NULL,
  `id_alumno` int(11) NOT NULL,
  `id_matricula` int(11) NOT NULL,
  `id_seccion` int(11) NOT NULL,
  `fecha_inscripcion` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `alumno_matricula`
--

INSERT INTO `alumno_matricula` (`id_alumno_matricula`, `id_alumno`, `id_matricula`, `id_seccion`, `fecha_inscripcion`) VALUES
(1, 1, 2, 1, '2025-01-05'),
(2, 4, 2, 1, '2025-01-04'),
(3, 5, 2, 1, '2025-01-05'),
(4, 6, 2, 1, '2025-01-05'),
(5, 7, 2, 1, '2025-01-05'),
(6, 8, 2, 1, '2025-01-05'),
(7, 9, 2, 1, '2025-01-05'),
(8, 10, 2, 1, '2025-01-05'),
(9, 11, 2, 1, '2025-01-05'),
(10, 12, 2, 1, '2025-01-05'),
(11, 13, 2, 1, '2025-01-05'),
(12, 14, 2, 1, '2025-01-05'),
(13, 15, 2, 1, '2025-01-05'),
(14, 16, 2, 1, '2025-01-05'),
(15, 17, 2, 1, '2025-01-05'),
(16, 18, 1, 2, '2025-01-08'),
(17, 19, 1, 1, '2025-01-08'),
(18, 20, 1, 3, '2025-01-08'),
(19, 21, 1, 1, '2025-01-08'),
(20, 22, 1, 2, '2025-01-08'),
(21, 23, 1, 2, '2025-01-08'),
(22, 24, 1, 4, '2025-01-08'),
(23, 25, 1, 4, '2025-01-08'),
(24, 26, 1, 2, '2025-01-08'),
(25, 3, 2, 5, '2025-01-15');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alumno_matricula_curso`
--

CREATE TABLE `alumno_matricula_curso` (
  `id_alumno_matricula_curso` int(11) NOT NULL,
  `id_alumno_matricula` int(11) DEFAULT NULL,
  `id_curso` int(11) DEFAULT NULL,
  `fecha_inscripcion` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `alumno_matricula_curso`
--

INSERT INTO `alumno_matricula_curso` (`id_alumno_matricula_curso`, `id_alumno_matricula`, `id_curso`, `fecha_inscripcion`) VALUES
(1, 1, 1, '2025-01-22'),
(2, 2, 1, '2025-01-22'),
(3, 3, 1, '2025-01-22'),
(4, 4, 1, '2025-01-22'),
(5, 5, 1, '2025-01-22'),
(6, 6, 1, '2025-01-22'),
(7, 7, 1, '2025-01-22'),
(8, 8, 1, '2025-01-22'),
(9, 9, 1, '2025-01-22'),
(10, 10, 1, '2025-01-22'),
(11, 11, 1, '2025-01-22'),
(12, 12, 1, '2025-01-22'),
(13, 13, 1, '2025-01-22'),
(14, 14, 1, '2025-01-22'),
(15, 15, 1, '2025-01-22'),
(16, 17, 1, '2025-01-22'),
(17, 19, 1, '2025-01-22'),
(18, 16, 1, '2025-01-22'),
(19, 20, 1, '2025-01-22'),
(20, 21, 1, '2025-01-22'),
(21, 24, 1, '2025-01-22'),
(22, 18, 1, '2025-01-22'),
(23, 1, 2, '2025-01-22'),
(24, 2, 2, '2025-01-22'),
(25, 3, 2, '2025-01-22'),
(26, 4, 2, '2025-01-22'),
(27, 5, 2, '2025-01-22'),
(28, 6, 2, '2025-01-22'),
(29, 7, 2, '2025-01-22'),
(30, 8, 2, '2025-01-22'),
(31, 9, 2, '2025-01-22'),
(32, 10, 2, '2025-01-22'),
(33, 11, 2, '2025-01-22'),
(34, 12, 2, '2025-01-22'),
(35, 13, 2, '2025-01-22'),
(36, 14, 2, '2025-01-22'),
(37, 15, 2, '2025-01-22'),
(38, 17, 2, '2025-01-22'),
(39, 19, 2, '2025-01-22'),
(40, 16, 2, '2025-01-22'),
(41, 20, 2, '2025-01-22'),
(42, 21, 2, '2025-01-22'),
(43, 24, 2, '2025-01-22'),
(44, 18, 2, '2025-01-22'),
(45, 1, 3, '2025-01-22'),
(46, 2, 3, '2025-01-22'),
(47, 3, 3, '2025-01-22'),
(48, 4, 3, '2025-01-22'),
(49, 5, 3, '2025-01-22'),
(50, 6, 3, '2025-01-22'),
(51, 7, 3, '2025-01-22'),
(52, 8, 3, '2025-01-22'),
(53, 9, 3, '2025-01-22'),
(54, 10, 3, '2025-01-22'),
(55, 11, 3, '2025-01-22'),
(56, 12, 3, '2025-01-22'),
(57, 13, 3, '2025-01-22'),
(58, 14, 3, '2025-01-22'),
(59, 15, 3, '2025-01-22'),
(60, 17, 3, '2025-01-22'),
(61, 19, 3, '2025-01-22'),
(62, 16, 3, '2025-01-22'),
(63, 20, 3, '2025-01-22'),
(64, 21, 3, '2025-01-22'),
(65, 24, 3, '2025-01-22'),
(66, 18, 3, '2025-01-22'),
(128, 22, 4, '2025-01-22'),
(129, 23, 4, '2025-01-22'),
(130, 25, 4, '2025-01-22'),
(131, 22, 5, '2025-01-22'),
(132, 23, 5, '2025-01-22'),
(133, 25, 5, '2025-01-22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `apoderado`
--

CREATE TABLE `apoderado` (
  `id_apoderado` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_institucion` int(11) NOT NULL,
  `codigo_apoderado` varchar(50) NOT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `apoderado`
--

INSERT INTO `apoderado` (`id_apoderado`, `id_usuario`, `id_institucion`, `codigo_apoderado`, `estado`) VALUES
(1, 4, 1, '00001-F-71806587', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asistencia`
--

CREATE TABLE `asistencia` (
  `id_asistencia` int(11) NOT NULL,
  `id_alumno_matricula_curso` int(11) NOT NULL,
  `fecha` datetime NOT NULL,
  `estado` enum('PRESENTE','AUSENTE','TARDANZA','JUSTIFICADO','PENDIENTE') NOT NULL DEFAULT 'AUSENTE',
  `observaciones` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `asistencia`
--

INSERT INTO `asistencia` (`id_asistencia`, `id_alumno_matricula_curso`, `fecha`, `estado`, `observaciones`) VALUES
(1, 1, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(2, 2, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(3, 3, '2025-01-29 08:00:00', 'PRESENTE', NULL),
(4, 4, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(5, 5, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(6, 6, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(7, 7, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(8, 8, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(9, 9, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(10, 10, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(11, 11, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(12, 12, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(13, 13, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(14, 14, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(15, 15, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(16, 16, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(17, 17, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(18, 18, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(19, 19, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(20, 20, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(21, 21, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(22, 22, '2025-01-29 08:00:00', 'PENDIENTE', NULL),
(32, 1, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(33, 2, '2025-01-01 00:00:00', 'AUSENTE', NULL),
(34, 3, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(35, 4, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(36, 5, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(37, 6, '2025-01-01 00:00:00', 'JUSTIFICADO', NULL),
(38, 7, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(39, 8, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(40, 9, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(41, 10, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(42, 11, '2025-01-01 00:00:00', 'AUSENTE', NULL),
(43, 12, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(44, 13, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(45, 14, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(46, 15, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(47, 16, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(48, 17, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(49, 18, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(50, 19, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(51, 20, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(52, 21, '2025-01-01 00:00:00', 'AUSENTE', NULL),
(53, 22, '2025-01-01 00:00:00', 'PRESENTE', NULL),
(54, 1, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(55, 2, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(56, 3, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(57, 4, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(58, 5, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(59, 6, '2025-01-02 00:00:00', 'JUSTIFICADO', NULL),
(60, 7, '2025-01-02 00:00:00', 'JUSTIFICADO', NULL),
(61, 8, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(62, 9, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(63, 10, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(64, 11, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(65, 12, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(66, 13, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(67, 14, '2025-01-02 00:00:00', 'AUSENTE', NULL),
(68, 15, '2025-01-02 00:00:00', 'JUSTIFICADO', NULL),
(69, 16, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(70, 17, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(71, 18, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(72, 19, '2025-01-02 00:00:00', 'JUSTIFICADO', NULL),
(73, 20, '2025-01-02 00:00:00', 'JUSTIFICADO', NULL),
(74, 21, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(75, 22, '2025-01-02 00:00:00', 'PRESENTE', NULL),
(76, 1, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(77, 2, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(78, 3, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(79, 4, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(80, 5, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(81, 6, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(82, 7, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(83, 8, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(84, 9, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(85, 10, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(86, 11, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(87, 12, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(88, 13, '2025-01-03 00:00:00', 'JUSTIFICADO', NULL),
(89, 14, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(90, 15, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(91, 16, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(92, 17, '2025-01-03 00:00:00', 'JUSTIFICADO', NULL),
(93, 18, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(94, 19, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(95, 20, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(96, 21, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(97, 22, '2025-01-03 00:00:00', 'PRESENTE', NULL),
(98, 1, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(99, 2, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(100, 3, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(101, 4, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(102, 5, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(103, 6, '2025-01-04 00:00:00', 'JUSTIFICADO', NULL),
(104, 7, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(105, 8, '2025-01-04 00:00:00', 'JUSTIFICADO', NULL),
(106, 9, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(107, 10, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(108, 11, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(109, 12, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(110, 13, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(111, 14, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(112, 15, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(113, 16, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(114, 17, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(115, 18, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(116, 19, '2025-01-04 00:00:00', 'AUSENTE', NULL),
(117, 20, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(118, 21, '2025-01-04 00:00:00', 'AUSENTE', NULL),
(119, 22, '2025-01-04 00:00:00', 'PRESENTE', NULL),
(120, 1, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(121, 2, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(122, 3, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(123, 4, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(124, 5, '2025-01-05 00:00:00', 'JUSTIFICADO', NULL),
(125, 6, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(126, 7, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(127, 8, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(128, 9, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(129, 10, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(130, 11, '2025-01-05 00:00:00', 'JUSTIFICADO', NULL),
(131, 12, '2025-01-05 00:00:00', 'JUSTIFICADO', NULL),
(132, 13, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(133, 14, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(134, 15, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(135, 16, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(136, 17, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(137, 18, '2025-01-05 00:00:00', 'JUSTIFICADO', NULL),
(138, 19, '2025-01-05 00:00:00', 'JUSTIFICADO', NULL),
(139, 20, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(140, 21, '2025-01-05 00:00:00', 'PRESENTE', NULL),
(141, 22, '2025-01-05 00:00:00', 'JUSTIFICADO', NULL),
(142, 1, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(143, 2, '2025-01-08 00:00:00', 'JUSTIFICADO', NULL),
(144, 3, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(145, 4, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(146, 5, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(147, 6, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(148, 7, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(149, 8, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(150, 9, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(151, 10, '2025-01-08 00:00:00', 'JUSTIFICADO', NULL),
(152, 11, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(153, 12, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(154, 13, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(155, 14, '2025-01-08 00:00:00', 'JUSTIFICADO', NULL),
(156, 15, '2025-01-08 00:00:00', 'JUSTIFICADO', NULL),
(157, 16, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(158, 17, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(159, 18, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(160, 19, '2025-01-08 00:00:00', 'JUSTIFICADO', NULL),
(161, 20, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(162, 21, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(163, 22, '2025-01-08 00:00:00', 'PRESENTE', NULL),
(164, 1, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(165, 2, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(166, 3, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(167, 4, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(168, 5, '2025-01-09 00:00:00', 'JUSTIFICADO', NULL),
(169, 6, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(170, 7, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(171, 8, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(172, 9, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(173, 10, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(174, 11, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(175, 12, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(176, 13, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(177, 14, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(178, 15, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(179, 16, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(180, 17, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(181, 18, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(182, 19, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(183, 20, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(184, 21, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(185, 22, '2025-01-09 00:00:00', 'PRESENTE', NULL),
(186, 1, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(187, 2, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(188, 3, '2025-01-10 00:00:00', 'JUSTIFICADO', NULL),
(189, 4, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(190, 5, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(191, 6, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(192, 7, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(193, 8, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(194, 9, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(195, 10, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(196, 11, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(197, 12, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(198, 13, '2025-01-10 00:00:00', 'JUSTIFICADO', NULL),
(199, 14, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(200, 15, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(201, 16, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(202, 17, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(203, 18, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(204, 19, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(205, 20, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(206, 21, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(207, 22, '2025-01-10 00:00:00', 'PRESENTE', NULL),
(208, 1, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(209, 2, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(210, 3, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(211, 4, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(212, 5, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(213, 6, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(214, 7, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(215, 8, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(216, 9, '2025-01-11 00:00:00', 'JUSTIFICADO', NULL),
(217, 10, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(218, 11, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(219, 12, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(220, 13, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(221, 14, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(222, 15, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(223, 16, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(224, 17, '2025-01-11 00:00:00', 'AUSENTE', NULL),
(225, 18, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(226, 19, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(227, 20, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(228, 21, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(229, 22, '2025-01-11 00:00:00', 'PRESENTE', NULL),
(230, 1, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(231, 2, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(232, 3, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(233, 4, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(234, 5, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(235, 6, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(236, 7, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(237, 8, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(238, 9, '2025-01-12 00:00:00', 'JUSTIFICADO', NULL),
(239, 10, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(240, 11, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(241, 12, '2025-01-12 00:00:00', 'JUSTIFICADO', NULL),
(242, 13, '2025-01-12 00:00:00', 'TARDANZA', NULL),
(243, 14, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(244, 15, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(245, 16, '2025-01-12 00:00:00', 'JUSTIFICADO', NULL),
(246, 17, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(247, 18, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(248, 19, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(249, 20, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(250, 21, '2025-01-12 00:00:00', 'PRESENTE', NULL),
(251, 22, '2025-01-12 00:00:00', 'JUSTIFICADO', NULL),
(252, 1, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(253, 2, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(254, 3, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(255, 4, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(256, 5, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(257, 6, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(258, 7, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(259, 8, '2025-01-15 00:00:00', 'TARDANZA', NULL),
(260, 9, '2025-01-15 00:00:00', 'TARDANZA', NULL),
(261, 10, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(262, 11, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(263, 12, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(264, 13, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(265, 14, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(266, 15, '2025-01-15 00:00:00', 'JUSTIFICADO', NULL),
(267, 16, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(268, 17, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(269, 18, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(270, 19, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(271, 20, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(272, 21, '2025-01-15 00:00:00', 'JUSTIFICADO', NULL),
(273, 22, '2025-01-15 00:00:00', 'PRESENTE', NULL),
(274, 1, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(275, 2, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(276, 3, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(277, 4, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(278, 5, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(279, 6, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(280, 7, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(281, 8, '2025-01-16 00:00:00', 'JUSTIFICADO', NULL),
(282, 9, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(283, 10, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(284, 11, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(285, 12, '2025-01-16 00:00:00', 'AUSENTE', NULL),
(286, 13, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(287, 14, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(288, 15, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(289, 16, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(290, 17, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(291, 18, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(292, 19, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(293, 20, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(294, 21, '2025-01-16 00:00:00', 'PRESENTE', NULL),
(295, 22, '2025-01-16 00:00:00', 'JUSTIFICADO', NULL),
(296, 1, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(297, 2, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(298, 3, '2025-01-17 00:00:00', 'TARDANZA', NULL),
(299, 4, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(300, 5, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(301, 6, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(302, 7, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(303, 8, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(304, 9, '2025-01-17 00:00:00', 'JUSTIFICADO', NULL),
(305, 10, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(306, 11, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(307, 12, '2025-01-17 00:00:00', 'TARDANZA', NULL),
(308, 13, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(309, 14, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(310, 15, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(311, 16, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(312, 17, '2025-01-17 00:00:00', 'JUSTIFICADO', NULL),
(313, 18, '2025-01-17 00:00:00', 'JUSTIFICADO', NULL),
(314, 19, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(315, 20, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(316, 21, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(317, 22, '2025-01-17 00:00:00', 'PRESENTE', NULL),
(318, 1, '2025-01-18 00:00:00', 'JUSTIFICADO', NULL),
(319, 2, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(320, 3, '2025-01-18 00:00:00', 'JUSTIFICADO', NULL),
(321, 4, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(322, 5, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(323, 6, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(324, 7, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(325, 8, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(326, 9, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(327, 10, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(328, 11, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(329, 12, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(330, 13, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(331, 14, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(332, 15, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(333, 16, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(334, 17, '2025-01-18 00:00:00', 'JUSTIFICADO', NULL),
(335, 18, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(336, 19, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(337, 20, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(338, 21, '2025-01-18 00:00:00', 'PRESENTE', NULL),
(339, 22, '2025-01-18 00:00:00', 'JUSTIFICADO', NULL),
(340, 1, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(341, 2, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(342, 3, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(343, 4, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(344, 5, '2025-01-19 00:00:00', 'JUSTIFICADO', NULL),
(345, 6, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(346, 7, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(347, 8, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(348, 9, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(349, 10, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(350, 11, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(351, 12, '2025-01-19 00:00:00', 'JUSTIFICADO', NULL),
(352, 13, '2025-01-19 00:00:00', 'JUSTIFICADO', NULL),
(353, 14, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(354, 15, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(355, 16, '2025-01-19 00:00:00', 'JUSTIFICADO', NULL),
(356, 17, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(357, 18, '2025-01-19 00:00:00', 'JUSTIFICADO', NULL),
(358, 19, '2025-01-19 00:00:00', 'AUSENTE', NULL),
(359, 20, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(360, 21, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(361, 22, '2025-01-19 00:00:00', 'PRESENTE', NULL),
(362, 1, '2025-01-22 00:00:00', 'TARDANZA', NULL),
(363, 2, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(364, 3, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(365, 4, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(366, 5, '2025-01-22 00:00:00', 'JUSTIFICADO', NULL),
(367, 6, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(368, 7, '2025-01-22 00:00:00', 'JUSTIFICADO', NULL),
(369, 8, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(370, 9, '2025-01-22 00:00:00', 'JUSTIFICADO', NULL),
(371, 10, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(372, 11, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(373, 12, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(374, 13, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(375, 14, '2025-01-22 00:00:00', 'TARDANZA', NULL),
(376, 15, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(377, 16, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(378, 17, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(379, 18, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(380, 19, '2025-01-22 00:00:00', 'JUSTIFICADO', NULL),
(381, 20, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(382, 21, '2025-01-22 00:00:00', 'PRESENTE', NULL),
(383, 22, '2025-01-22 00:00:00', 'JUSTIFICADO', NULL),
(384, 1, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(385, 2, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(386, 3, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(387, 4, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(388, 5, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(389, 6, '2025-01-23 00:00:00', 'JUSTIFICADO', NULL),
(390, 7, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(391, 8, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(392, 9, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(393, 10, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(394, 11, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(395, 12, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(396, 13, '2025-01-23 00:00:00', 'JUSTIFICADO', NULL),
(397, 14, '2025-01-23 00:00:00', 'JUSTIFICADO', NULL),
(398, 15, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(399, 16, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(400, 17, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(401, 18, '2025-01-23 00:00:00', 'AUSENTE', NULL),
(402, 19, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(403, 20, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(404, 21, '2025-01-23 00:00:00', 'JUSTIFICADO', NULL),
(405, 22, '2025-01-23 00:00:00', 'PRESENTE', NULL),
(406, 1, '2025-01-24 00:00:00', 'JUSTIFICADO', NULL),
(407, 2, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(408, 3, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(409, 4, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(410, 5, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(411, 6, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(412, 7, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(413, 8, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(414, 9, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(415, 10, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(416, 11, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(417, 12, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(418, 13, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(419, 14, '2025-01-24 00:00:00', 'JUSTIFICADO', NULL),
(420, 15, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(421, 16, '2025-01-24 00:00:00', 'JUSTIFICADO', NULL),
(422, 17, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(423, 18, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(424, 19, '2025-01-24 00:00:00', 'JUSTIFICADO', NULL),
(425, 20, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(426, 21, '2025-01-24 00:00:00', 'JUSTIFICADO', NULL),
(427, 22, '2025-01-24 00:00:00', 'PRESENTE', NULL),
(428, 1, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(429, 2, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(430, 3, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(431, 4, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(432, 5, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(433, 6, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(434, 7, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(435, 8, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(436, 9, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(437, 10, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(438, 11, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(439, 12, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(440, 13, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(441, 14, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(442, 15, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(443, 16, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(444, 17, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(445, 18, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(446, 19, '2025-01-25 00:00:00', 'JUSTIFICADO', NULL),
(447, 20, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(448, 21, '2025-01-25 00:00:00', 'JUSTIFICADO', NULL),
(449, 22, '2025-01-25 00:00:00', 'PRESENTE', NULL),
(450, 1, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(451, 2, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(452, 3, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(453, 4, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(454, 5, '2025-01-26 00:00:00', 'JUSTIFICADO', NULL),
(455, 6, '2025-01-26 00:00:00', 'AUSENTE', NULL),
(456, 7, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(457, 8, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(458, 9, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(459, 10, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(460, 11, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(461, 12, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(462, 13, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(463, 14, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(464, 15, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(465, 16, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(466, 17, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(467, 18, '2025-01-26 00:00:00', 'JUSTIFICADO', NULL),
(468, 19, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(469, 20, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(470, 21, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(471, 22, '2025-01-26 00:00:00', 'PRESENTE', NULL),
(543, 1, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(544, 2, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(545, 3, '2025-01-30 08:00:00', 'AUSENTE', 'No asistió a clases'),
(546, 4, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(547, 5, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(548, 6, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(549, 7, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(550, 8, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(551, 9, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(552, 10, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(553, 11, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(554, 12, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(555, 13, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(556, 14, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(557, 15, '2025-01-30 08:00:00', 'TARDANZA', 'Llegó 10 minutos tarde'),
(558, 16, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(559, 17, '2025-01-30 08:00:00', 'JUSTIFICADO', 'Enfermedad con certificado médico'),
(560, 18, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(561, 19, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(562, 20, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(563, 21, '2025-01-30 08:00:00', 'PENDIENTE', NULL),
(564, 22, '2025-01-30 08:00:00', 'PRESENTE', 'Llegó a tiempo'),
(580, 131, '2025-01-30 17:31:06', 'PENDIENTE', NULL),
(581, 132, '2025-01-30 17:31:06', 'PENDIENTE', NULL),
(582, 133, '2025-01-30 17:31:06', 'PENDIENTE', NULL),
(583, 131, '2025-01-31 17:35:13', 'PENDIENTE', NULL),
(584, 132, '2025-01-31 17:35:13', 'PENDIENTE', NULL),
(585, 133, '2025-01-31 17:35:13', 'PENDIENTE', NULL),
(586, 131, '2025-01-31 17:43:57', 'PENDIENTE', NULL),
(587, 132, '2025-01-31 17:43:57', 'PENDIENTE', NULL),
(588, 133, '2025-01-31 17:43:57', 'PENDIENTE', NULL),
(589, 131, '2025-02-01 17:53:50', 'PRESENTE', NULL),
(590, 132, '2025-02-01 17:53:50', 'PRESENTE', NULL),
(591, 133, '2025-02-01 17:53:50', 'PRESENTE', NULL),
(592, 1, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(593, 2, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(594, 3, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(595, 4, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(596, 5, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(597, 6, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(598, 7, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(599, 8, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(600, 9, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(601, 10, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(602, 11, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(603, 12, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(604, 13, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(605, 14, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(606, 15, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(607, 16, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(608, 17, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(609, 18, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(610, 19, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(611, 20, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(612, 21, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(613, 22, '2025-01-31 17:59:47', 'PENDIENTE', NULL),
(623, 1, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(624, 2, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(625, 3, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(626, 4, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(627, 5, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(628, 6, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(629, 7, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(630, 8, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(631, 9, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(632, 10, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(633, 11, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(634, 12, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(635, 13, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(636, 14, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(637, 15, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(638, 16, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(639, 17, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(640, 18, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(641, 19, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(642, 20, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(643, 21, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(644, 22, '2025-02-01 18:03:13', 'PENDIENTE', NULL),
(654, 131, '2025-02-02 18:04:17', 'JUSTIFICADO', NULL),
(655, 132, '2025-02-02 18:04:17', 'TARDANZA', NULL),
(656, 133, '2025-02-02 18:04:17', 'TARDANZA', NULL),
(657, 131, '2025-02-03 18:10:18', 'PENDIENTE', NULL),
(658, 132, '2025-02-03 18:10:18', 'PENDIENTE', NULL),
(659, 133, '2025-02-03 18:10:18', 'PENDIENTE', NULL),
(660, 131, '2025-02-06 23:17:47', 'AUSENTE', NULL),
(661, 132, '2025-02-06 23:17:47', 'JUSTIFICADO', NULL),
(662, 133, '2025-02-06 23:17:47', 'TARDANZA', NULL),
(663, 131, '2025-02-05 23:18:36', 'PRESENTE', NULL),
(664, 132, '2025-02-05 23:18:36', 'TARDANZA', NULL),
(665, 133, '2025-02-05 23:18:36', 'PRESENTE', NULL),
(666, 131, '2025-02-04 23:19:08', 'AUSENTE', NULL),
(667, 132, '2025-02-04 23:19:08', 'JUSTIFICADO', NULL),
(668, 133, '2025-02-04 23:19:08', 'PRESENTE', NULL),
(669, 131, '2025-02-07 16:55:56', 'PENDIENTE', NULL),
(670, 132, '2025-02-07 16:55:56', 'PENDIENTE', NULL),
(671, 133, '2025-02-07 16:55:56', 'PENDIENTE', NULL),
(672, 131, '2025-02-10 16:56:19', 'PRESENTE', NULL),
(673, 132, '2025-02-10 16:56:19', 'PRESENTE', NULL),
(674, 133, '2025-02-10 16:56:19', 'TARDANZA', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `aviso`
--

CREATE TABLE `aviso` (
  `id_aviso` int(11) NOT NULL,
  `id_alumno` int(11) NOT NULL,
  `titulo` varchar(255) NOT NULL,
  `descripcion` text NOT NULL,
  `fecha_hora` datetime NOT NULL,
  `tipo` enum('Académico','Asistencia','Conducta','General') NOT NULL DEFAULT 'General',
  `prioridad` enum('Alta','Media','Baja') NOT NULL DEFAULT 'Media',
  `autor` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `constantes`
--

CREATE TABLE `constantes` (
  `id` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `valor` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `constantes`
--

INSERT INTO `constantes` (`id`, `nombre`, `valor`) VALUES
(1, 'TOKEN_LIFETIME', '5');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `coordinador`
--

CREATE TABLE `coordinador` (
  `id_coordinador` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_institucion` int(11) NOT NULL,
  `codigo_coordinador` varchar(50) NOT NULL,
  `especialidad` varchar(255) NOT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `coordinador`
--

INSERT INTO `coordinador` (`id_coordinador`, `id_usuario`, `id_institucion`, `codigo_coordinador`, `especialidad`, `estado`) VALUES
(2, 4, 1, '00001-C-71806587', 'Licenciado', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `curso`
--

CREATE TABLE `curso` (
  `id_curso` int(11) NOT NULL,
  `id_grado` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `curso`
--

INSERT INTO `curso` (`id_curso`, `id_grado`, `nombre`, `descripcion`, `estado`) VALUES
(1, 1, 'Matemática', 'El curso de Matemáticas es una asignatura fundamental que se centra en el estudio de conceptos y técnicas matemáticas esenciales. Se abordan temas como aritmética, álgebra, geometría, trigonometría y cálculo, dependiendo del nivel del curso. Los estudiantes desarrollarán habilidades para resolver problemas, realizar análisis críticos y aplicar razonamientos lógicos. El curso también fomenta la apreciación de las matemáticas en el mundo real y su aplicación en diversas disciplinas, desde las ciencias hasta la economía y la ingeniería. A lo largo del curso, los estudiantes trabajarán en una variedad de ejercicios y proyectos que les ayudarán a entender y a manejar conceptos matemáticos de manera práctica y efectiva.', 'Activo'),
(2, 1, 'Comunicación', 'Curso de letras donde se ve toda la literatura y comunicación.', 'Activo'),
(3, 1, 'Ciencias Sociales', 'Curso donde se ve toda la ciencia de la humanidad.', 'Activo'),
(4, 2, 'Matematica 2do', 'Curso de mates', 'Activo'),
(5, 2, 'Logica', '................', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `curso_docente`
--

CREATE TABLE `curso_docente` (
  `id_curso_docente` int(11) NOT NULL,
  `id_curso` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `curso_docente`
--

INSERT INTO `curso_docente` (`id_curso_docente`, `id_curso`, `id_docente`) VALUES
(1, 1, 1),
(2, 3, 2),
(3, 2, 2),
(4, 2, 9),
(5, 2, 7),
(6, 3, 7),
(7, 3, 6),
(9, 3, 1),
(10, 5, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `curso_docente_horario`
--

CREATE TABLE `curso_docente_horario` (
  `id_horario` int(11) NOT NULL,
  `id_curso_docente` int(11) NOT NULL,
  `dia` varchar(20) NOT NULL,
  `hora_inicio` time NOT NULL,
  `hora_fin` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `docente`
--

CREATE TABLE `docente` (
  `id_docente` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_institucion` int(11) NOT NULL,
  `codigo_docente` varchar(50) NOT NULL,
  `especialidad` varchar(255) DEFAULT NULL,
  `estado` enum('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `docente`
--

INSERT INTO `docente` (`id_docente`, `id_usuario`, `id_institucion`, `codigo_docente`, `especialidad`, `estado`) VALUES
(1, 4, 1, '00001-T-71806587', 'Licenciado en matemática practica', 'Activo'),
(2, 4, 2, '00001-T-71806588', 'Matematicas', 'Activo'),
(4, 67, 1, '00001-D-12121212', 'Ciencias de telecomunicacion', 'Activo'),
(6, 66, 1, '00001-T-25252525', 'Ciencias de la quimica', 'Activo'),
(7, 68, 1, '00001-T-36363636', 'Ciencias de la fisica', 'Activo'),
(9, 70, 1, '00001-T-45454545', 'Ciencias de telecomunicacion', 'Activo'),
(10, 79, 1, '00001-T-71717474', 'Matematicas', 'Activo'),
(11, 49, 1, '00001-T-71500070', 'Matematicas Avanzadas II', 'Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `etapa_escolar`
--

CREATE TABLE `etapa_escolar` (
  `id_etapa` int(11) NOT NULL,
  `id_matricula` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `etapa_escolar`
--

INSERT INTO `etapa_escolar` (`id_etapa`, `id_matricula`, `nombre`, `fecha_inicio`, `fecha_fin`) VALUES
(1, 2, 'Primer Bimestre', '2024-03-04', '2024-05-12'),
(2, 2, 'Segundo Bimestre', '2024-05-13', '2024-07-21'),
(3, 2, 'Tercer Bimestre', '2024-07-22', '2024-09-29'),
(4, 2, 'Cuarto Bimestre', '2024-09-30', '2024-12-08');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `etapa_planificacion`
--

CREATE TABLE `etapa_planificacion` (
  `id_etapa_planificacion` int(11) NOT NULL,
  `id_etapa` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `etapa_planificacion`
--

INSERT INTO `etapa_planificacion` (`id_etapa_planificacion`, `id_etapa`, `nombre`, `fecha_inicio`, `fecha_fin`) VALUES
(1, 1, 'Semana 1', '2024-03-04', '2024-03-10'),
(2, 1, 'Semana 2', '2024-03-11', '2024-03-17'),
(3, 1, 'Semana 3', '2024-03-18', '2024-03-24'),
(4, 1, 'Semana 4', '2024-03-25', '2024-03-31'),
(5, 1, 'Semana 5', '2024-04-01', '2024-04-07'),
(6, 1, 'Semana 6', '2024-04-08', '2024-04-14'),
(7, 1, 'Semana 7', '2024-04-15', '2024-04-21'),
(8, 1, 'Semana 8', '2024-04-22', '2024-04-28'),
(9, 1, 'Semana 9', '2024-04-29', '2024-05-05'),
(10, 1, 'Semana 10', '2024-05-06', '2024-05-12'),
(11, 2, 'Semana 1', '2024-05-13', '2024-05-19'),
(12, 2, 'Semana 2', '2024-05-20', '2024-05-26'),
(13, 2, 'Semana 3', '2024-05-27', '2024-06-02'),
(14, 2, 'Semana 4', '2024-06-03', '2024-06-09'),
(15, 2, 'Semana 5', '2024-06-10', '2024-06-16'),
(16, 2, 'Semana 6', '2024-06-17', '2024-06-23'),
(17, 2, 'Semana 7', '2024-06-24', '2024-06-30'),
(18, 2, 'Semana 8', '2024-07-01', '2024-07-07'),
(19, 2, 'Semana 9', '2024-07-08', '2024-07-14'),
(20, 2, 'Semana 10', '2024-07-15', '2024-07-21'),
(21, 3, 'Semana 1', '2024-07-22', '2024-07-28'),
(22, 3, 'Semana 2', '2024-07-29', '2024-08-04'),
(23, 3, 'Semana 3', '2024-08-05', '2024-08-11'),
(24, 3, 'Semana 4', '2024-08-12', '2024-08-18'),
(25, 3, 'Semana 5', '2024-08-19', '2024-08-25'),
(26, 3, 'Semana 6', '2024-08-26', '2024-09-01'),
(27, 3, 'Semana 7', '2024-09-02', '2024-09-08'),
(28, 3, 'Semana 8', '2024-09-09', '2024-09-15'),
(29, 3, 'Semana 9', '2024-09-16', '2024-09-22'),
(30, 3, 'Semana 10', '2024-09-23', '2024-09-29'),
(31, 4, 'Semana 1', '2024-09-30', '2024-10-06'),
(32, 4, 'Semana 2', '2024-10-07', '2024-10-13'),
(33, 4, 'Semana 3', '2024-10-14', '2024-10-20'),
(34, 4, 'Semana 4', '2024-10-21', '2024-10-27'),
(35, 4, 'Semana 5', '2024-10-28', '2024-11-03'),
(36, 4, 'Semana 6', '2024-11-04', '2024-11-10'),
(37, 4, 'Semana 7', '2024-11-11', '2024-11-17'),
(38, 4, 'Semana 8', '2024-11-18', '2024-11-24'),
(39, 4, 'Semana 9', '2024-11-25', '2024-12-01'),
(40, 4, 'Semana 10', '2024-12-02', '2024-12-08');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `grado`
--

CREATE TABLE `grado` (
  `id_grado` int(11) NOT NULL,
  `id_nivel` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `grado`
--

INSERT INTO `grado` (`id_grado`, `id_nivel`, `nombre`) VALUES
(1, 1, '1RO'),
(2, 1, '2DO'),
(3, 1, '3RO'),
(4, 2, 'Primero'),
(5, 2, 'Segundo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `institucion`
--

CREATE TABLE `institucion` (
  `id_institucion` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `tipo` enum('Publica','Privada') NOT NULL,
  `fecha_creacion` date NOT NULL,
  `url_imagen` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `institucion`
--

INSERT INTO `institucion` (`id_institucion`, `nombre`, `direccion`, `telefono`, `email`, `tipo`, `fecha_creacion`, `url_imagen`) VALUES
(1, 'Instituto Educativo Nacional', 'Calle Falsa 123', '555-1234', 'contacto@instituto.com', 'Publica', '2024-11-20', 'img/institucion/logo.png'),
(2, 'Institucion Aleatoria', 'Jr. las petunias', '952547865', 'institucionx@gmail.com', 'Privada', '0000-00-00', 'https://png.pngtree.com/png-clipart/20230506/original/pngtree-education-logo-and-school-badge-design-template-png-image_9146122.png'),
(3, 'TEST', 'TEST', 'TEST', 'TEST', 'Publica', '0000-00-00', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs`
--

CREATE TABLE `logs` (
  `id` int(11) NOT NULL,
  `endpoint` varchar(255) NOT NULL,
  `time` datetime NOT NULL,
  `data` text NOT NULL,
  `status` int(11) NOT NULL,
  `response` text DEFAULT NULL,
  `error` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `logs`
--

INSERT INTO `logs` (`id`, `endpoint`, `time`, `data`, `status`, `response`, `error`) VALUES
(1, 'Login', '2024-11-26 22:39:42', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', '1062 (23000): Duplicate entry \'1\' for key \'PRIMARY\''),
(2, 'Login', '2024-11-26 22:43:23', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'e50e59a6-ac8a-11ef-af2b-282801a11dbf\'}', NULL),
(3, 'Login', '2024-11-27 13:14:02', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'863508ab-ad04-11ef-af2b-282801a11dbf\'}', NULL),
(4, 'Login', '2024-11-27 20:49:38', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'2b6082d3-ad44-11ef-af2b-282801a11dbf\'}', NULL),
(5, 'Login', '2024-11-28 14:05:11', '{\'email\': \'anVhbi5wZXJlekBpbnN0aXR1dG8uY29t\', \'password\': \'cGFzc3dvcmQxMjM=\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'d5bd789e-add4-11ef-af2b-282801a11dbf\'}', NULL),
(6, 'Login', '2024-11-28 14:11:38', '{\'email\': \'anVhbi5wZXJlekBpbnN0aXR1dG8uY29t\', \'password\': \'cGFzc3dvcmQxMjM=\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', '1062 (23000): Duplicate entry \'1\' for key \'PRIMARY\''),
(7, 'Login', '2024-11-28 15:04:50', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de base64: Invalid base64-encoded string: number of data characters (21) cannot be 1 more than a multiple of 4'),
(8, 'Login', '2024-11-28 15:05:00', '{\'email\': \'anVhbi5wZXJlekBpbnN0aXR1dG8uY29t\', \'password\': \'cGFzc3dvcmQxMjM=\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'30fc2438-addd-11ef-af2b-282801a11dbf\'}', NULL),
(9, 'RegisterInstitution', '2024-11-28 15:05:04', '{\'email\': \'dGVzdEBtYWlsLmNvbQ==\', \'password\': \'cGFzc3dvcmQxMjM=\', \'name\': \'Sm9obiBEb2U=\', \'role_id\': \'MQ==\', \'institution_id\': \'MQ==\', \'phone\': \'KzU3MTEyMzQ1Njc4OTA=\', \'address\': \'U29tZSBzdHJlZXQsIENpdHk=\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error inesperado: El texto no puede estar vacío.'),
(10, 'RegisterInstitution', '2024-11-28 15:13:06', '{\'name\': \'RVJST1IgQ09SUA==\', \'address\': \'Q2FsbGUgZmFsc2EgMTIz\', \'phone\': \'OTk5OTk5OTk5\', \'email\': \'dGVzdC1pZUBleG0uY29t\', \'coordinator_password\': \'MTIzNDU2Nzg=\', \'coordinator_email\': \'Y29vcjFAZ21haWwuY29t\', \'coordinator_name\': \'MQUGFuY3JhY2lvIDEyMw==\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de decodificación UTF-8: \'utf-8\' codec can\'t decode byte 0xe6 in position 4: invalid continuation byte'),
(11, 'RegisterInstitution', '2024-11-28 15:15:48', '{\'name\': \'Some name\', \'address\': \'Some address\', \'phone\': \'123456789\', \'email\': \'example@email.com\', \'coordinator_password\': \'password123\', \'coordinator_email\': \'coordinator1@gmail.com\', \'coordinator_name\': \'coordinator\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de decodificación UTF-8: \'utf-8\' codec can\'t decode byte 0x89 in position 1: invalid start byte'),
(12, 'RegisterInstitution', '2024-11-28 15:16:16', '{\'name\': \'RVJST1IgQ09SUA==\', \'address\': \'Q2FsbGUgZmFsc2EgMTIz\', \'phone\': \'OTk5OTk5OTk5\', \'email\': \'dGVzdC1pZUBleG0uY29t\', \'coordinator_password\': \'MTIzNDU2Nzg=\', \'coordinator_email\': \'Y29vcjFAZ21haWwuY29t\', \'coordinator_name\': \'MQUGFuY3JhY2lvIDEyMw==\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de decodificación UTF-8: \'utf-8\' codec can\'t decode byte 0xe6 in position 4: invalid continuation byte'),
(13, 'RegisterInstitution', '2024-11-28 15:18:58', '{\'name\': \'RVJST1IgQ09SUA==\', \'address\': \'Q2FsbGUgZmFsc2EgMTIz\', \'phone\': \'OTk5OTk5OTk5\', \'email\': \'dGVzdC1pZUBleG0uY29t\', \'coordinator_password\': \'MTIzNDU2Nzg=\', \'coordinator_email\': \'Y29vcjFAZ21haWwuY29t\', \'coordinator_name\': \'MQUGFuY3JhY2lvIDEyMw==\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de decodificación UTF-8: \'utf-8\' codec can\'t decode byte 0xe6 in position 4: invalid continuation byte\nText : MQUGFuY3JhY2lvIDEyMw=='),
(14, 'RegisterInstitution', '2024-11-28 15:19:59', '{\'name\': \'RVJST1IgQ09SUA==\', \'address\': \'Q2FsbGUgZmFsc2EgMTIz\', \'phone\': \'OTk5OTk5OTk5\', \'email\': \'dGVzdC1pZUBleG0uY29t\', \'coordinator_password\': \'MTIzNDU2Nzg=\', \'coordinator_email\': \'Y29vcjFAZ21haWwuY29t\', \'coordinator_name\': \'S2V2aW4gRHVyYW4=\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', '1146 (42S02): Table \'sistema_educativo.institutions\' doesn\'t exist'),
(15, 'Login', '2024-12-01 14:09:11', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de base64: Invalid base64-encoded string: number of data characters (21) cannot be 1 more than a multiple of 4\nText : juan.perez@instituto.com'),
(16, 'Login', '2024-12-01 14:17:12', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de base64: Invalid base64-encoded string: number of data characters (21) cannot be 1 more than a multiple of 4\nText : juan.perez@instituto.com'),
(17, 'Login', '2024-12-01 14:19:48', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de base64: Invalid base64-encoded string: number of data characters (21) cannot be 1 more than a multiple of 4\nText : juan.perez@instituto.com'),
(18, 'Login', '2024-12-01 14:23:10', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'TG8gc2VudGltb3Mgb2N1cnJpw7MgdW4gZXJyb3IgaW5lc3BlcmFkby4gUG9yIGZhdm9yLCBpbnRlbnRlIG51ZXZhbWVudGUgbcOhcyB0YXJkZS4=\'}', 'Error de base64: Invalid base64-encoded string: number of data characters (21) cannot be 1 more than a multiple of 4\nText : juan.perez@instituto.com'),
(19, 'Login', '2024-12-01 14:25:48', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'3645a416-b033-11ef-af2b-282801a11dbf\'}', NULL),
(20, 'Login', '2024-12-01 17:58:50', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'Lo sentimos ocurrió un error inesperado. Por favor, intente nuevamente más tarde.\'}', 'tuple index out of range'),
(21, 'Login', '2024-12-01 18:02:38', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', NULL),
(22, 'Login', '2024-12-01 18:08:55', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', NULL),
(23, 'Login', '2024-12-01 18:11:15', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', NULL),
(24, 'Login', '2024-12-01 18:12:48', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', NULL),
(25, 'Login', '2024-12-01 18:13:49', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', '(\'1104c9c3-b053-11ef-af2b-282801a11dbf\',)'),
(26, 'Login', '2024-12-01 18:58:45', '{\'email\': \'juan.perez@instituto.com\', \'password\': \'password123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'12345678\', \'num_documento\': \'57e4cbb2-b059-11ef-af2b-282801a11dbf\', \'entities\': []}', NULL),
(27, 'Login', '2024-12-01 19:17:35', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'71806587\', \'num_documento\': \'f9128e28-b05b-11ef-af2b-282801a11dbf\', \'entities\': []}', NULL),
(28, 'Login', '2024-12-01 19:17:41', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'Lo sentimos ocurrió un error inesperado. Por favor, intente nuevamente más tarde.\'}', '1062 (23000): Duplicate entry \'4\' for key \'PRIMARY\''),
(29, 'Login', '2024-12-01 20:05:05', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'71806587\', \'num_documento\': \'9c20cb6e-b062-11ef-af2b-282801a11dbf\', \'entities\': []}', NULL),
(30, 'Login', '2024-12-01 20:52:50', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'71806587\', \'num_documento\': \'477a466a-b069-11ef-af2b-282801a11dbf\', \'entities\': []}', NULL),
(31, 'Login', '2024-12-01 21:17:52', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 500, '{\'status\': \'FAILED\', \'message\': \'Lo sentimos ocurrió un error inesperado. Por favor, intente nuevamente más tarde.\'}', 'name \'son\' is not defined'),
(32, 'Login', '2024-12-01 21:18:39', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'71806587\', \'num_documento\': \'e2beb511-b06c-11ef-af2b-282801a11dbf\', \'entities\': \'[]\'}', NULL),
(33, 'Login', '2024-12-01 21:25:37', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'71806587\', \'num_documento\': \'dc23fec8-b06d-11ef-af2b-282801a11dbf\', \'entities\': \'[]\'}', NULL),
(34, 'Login', '2024-12-01 21:28:32', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'446f6456-b06e-11ef-af2b-282801a11dbf\', \'num_documento\': \'71806587\', \'entities\': [{\'id\': 3, \'id_institucion\': 1, \'codigo\': \'00001-S-71806587\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-T-71806587\'}, {\'id\': 2, \'id_institucion\': 1, \'codigo\': \'00001-C-71806587\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-F-71806587\'}]}', NULL),
(35, 'Login', '2024-12-01 21:41:30', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'141ef1a8-b070-11ef-af2b-282801a11dbf\', \'num_documento\': \'71806587\', \'entities\': [{\'id\': 3, \'id_institucion\': 1, \'codigo\': \'00001-S-71806587\', \'rol\': \'Alumno\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-T-71806587\', \'rol\': \'Docente\'}, {\'id\': 2, \'id_institucion\': 1, \'codigo\': \'00001-C-71806587\', \'rol\': \'Coordinador\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-F-71806587\', \'rol\': \'Apoderado\'}]}', NULL),
(36, 'Login', '2024-12-01 22:00:18', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'b43c2981-b072-11ef-af2b-282801a11dbf\', \'num_documento\': \'71806587\', \'entities\': [{\'id\': 3, \'id_institucion\': 1, \'codigo\': \'00001-S-71806587\', \'rol\': \'Alumno\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-T-71806587\', \'rol\': \'Docente\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 2, \'id_institucion\': 1, \'codigo\': \'00001-C-71806587\', \'rol\': \'Coordinador\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-F-71806587\', \'rol\': \'Apoderado\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}]}', NULL),
(37, 'Login', '2024-12-01 22:00:45', '{\'email\': \'admin@error.com\', \'password\': \'123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', '(\'0\',)'),
(38, 'Login', '2024-12-03 17:11:44', '{\'email\': \'admin@error.com\', \'password\': \'admin1123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', '(\'0\',)'),
(39, 'Login', '2024-12-03 17:12:14', '{\'email\': \'admin@error.com\', \'password\': \'admin1123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', '(\'0\',)'),
(40, 'Login', '2024-12-03 17:13:29', '{\'email\': \'admin@error.com\', \'password\': \'admin1123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', '(\'0\',)'),
(41, 'Login', '2024-12-03 17:15:55', '{\'email\': \'admin@error.com\', \'password\': \'admin1123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', '(\'0\',)'),
(42, 'Login', '2024-12-03 17:21:12', '{\'email\': \'admin@error.com\', \'password\': \'admin1123\'}', 300, '{\'status\': \'FAILED\', \'message\': \'El correo electrónico o la contraseña ingresados no son válidos. Por favor, verifica tus datos e inténtalo nuevamente.\'}', '(\'0\',)'),
(43, 'Login', '2024-12-03 17:21:44', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'1ef08fb5-b1de-11ef-af2b-282801a11dbf\', \'num_documento\': \'71806587\', \'entities\': [{\'id\': 3, \'id_institucion\': 1, \'codigo\': \'00001-S-71806587\', \'rol\': \'Alumno\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-T-71806587\', \'rol\': \'Docente\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 2, \'id_institucion\': 1, \'codigo\': \'00001-C-71806587\', \'rol\': \'Coordinador\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-F-71806587\', \'rol\': \'Apoderado\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}]}', NULL),
(44, 'Login', '2024-12-05 13:42:50', '{\'email\': \'admin@error.com\', \'password\': \'admin123\'}', 200, '{\'status\': \'SUCCESS\', \'message\': \'\', \'token\': \'df1d0716-b351-11ef-af2b-282801a11dbf\', \'num_documento\': \'71806587\', \'entities\': [{\'id\': 3, \'id_institucion\': 1, \'codigo\': \'00001-S-71806587\', \'rol\': \'Alumno\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-T-71806587\', \'rol\': \'Docente\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 2, \'id_institucion\': 1, \'codigo\': \'00001-C-71806587\', \'rol\': \'Coordinador\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}, {\'id\': 1, \'id_institucion\': 1, \'codigo\': \'00001-F-71806587\', \'rol\': \'Apoderado\', \'nombre_ie\': \'Instituto Educativo Nacional\', \'url_imagen_ie\': \'img/institucion/logo.png\'}]}', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `matricula`
--

CREATE TABLE `matricula` (
  `id_matricula` int(11) NOT NULL,
  `id_institucion` int(11) NOT NULL,
  `nombre_matricula` varchar(255) NOT NULL,
  `anio_academico` year(4) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` enum('Abierta','Cerrada') DEFAULT 'Abierta'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `matricula`
--

INSERT INTO `matricula` (`id_matricula`, `id_institucion`, `nombre_matricula`, `anio_academico`, `fecha_inicio`, `fecha_fin`, `estado`) VALUES
(1, 1, 'IE EXM 2023', '2023', '2023-03-01', '2023-12-15', 'Abierta'),
(2, 1, 'IE EXM 2024', '2024', '2024-03-01', '2024-12-15', 'Abierta'),
(4, 1, 'IE EXM 2023', '2022', '2022-01-01', '2022-12-01', 'Abierta');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `nivel`
--

CREATE TABLE `nivel` (
  `id_nivel` int(11) NOT NULL,
  `id_institucion` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `nivel`
--

INSERT INTO `nivel` (`id_nivel`, `id_institucion`, `nombre`) VALUES
(1, 1, 'Secundaria'),
(2, 1, 'Primaria');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `nota`
--

CREATE TABLE `nota` (
  `id_nota` int(11) NOT NULL,
  `id_etapa_escolar` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `peso` decimal(5,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `nota`
--

INSERT INTO `nota` (`id_nota`, `id_etapa_escolar`, `nombre`, `peso`) VALUES
(1, 1, 'Examen Parcial', 0.40),
(2, 1, 'Trabajo de Proyecto', 0.30),
(3, 1, 'Participación en Clase', 0.30),
(4, 2, 'Examen Parcial', 0.50),
(5, 2, 'Trabajo de Proyecto', 0.20),
(6, 2, 'Tareas y Ejercicios', 0.30),
(7, 3, 'Examen Final', 0.60),
(8, 3, 'Trabajo de Proyecto', 0.25),
(9, 3, 'Participación en Clase', 0.15),
(10, 4, 'Examen Final', 0.70),
(11, 4, 'Trabajo de Proyecto', 0.20),
(12, 4, 'Participación en Clase', 0.10);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `nota_alumno_curso`
--

CREATE TABLE `nota_alumno_curso` (
  `id_nota_alumno_curso` int(11) NOT NULL,
  `id_alumno_matricula_curso` int(11) NOT NULL,
  `id_nota` int(11) NOT NULL,
  `nota_obtenida` decimal(5,2) NOT NULL,
  `fecha` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `nota_alumno_curso`
--

INSERT INTO `nota_alumno_curso` (`id_nota_alumno_curso`, `id_alumno_matricula_curso`, `id_nota`, `nota_obtenida`, `fecha`) VALUES
(1, 1, 1, 0.00, '2025-01-22'),
(2, 1, 2, 0.00, '2025-01-22'),
(3, 1, 3, 0.00, '2025-01-22'),
(4, 2, 1, 0.00, '2025-01-22'),
(5, 2, 2, 0.00, '2025-01-22'),
(6, 2, 3, 0.00, '2025-01-22'),
(7, 3, 1, 0.00, '2025-01-22'),
(8, 3, 2, 0.00, '2025-01-22'),
(9, 3, 3, 0.00, '2025-01-22'),
(10, 4, 1, 0.00, '2025-01-22'),
(11, 4, 2, 0.00, '2025-01-22'),
(12, 4, 3, 0.00, '2025-01-22'),
(13, 5, 1, 0.00, '2025-01-22'),
(14, 5, 2, 0.00, '2025-01-22'),
(15, 5, 3, 0.00, '2025-01-22'),
(16, 6, 1, 0.00, '2025-01-22'),
(17, 6, 2, 0.00, '2025-01-22'),
(18, 6, 3, 0.00, '2025-01-22'),
(19, 7, 1, 0.00, '2025-01-22'),
(20, 7, 2, 0.00, '2025-01-22'),
(21, 7, 3, 0.00, '2025-01-22'),
(22, 8, 1, 0.00, '2025-01-22'),
(23, 8, 2, 0.00, '2025-01-22'),
(24, 8, 3, 0.00, '2025-01-22'),
(25, 9, 1, 0.00, '2025-01-22'),
(26, 9, 2, 0.00, '2025-01-22'),
(27, 9, 3, 0.00, '2025-01-22'),
(28, 10, 1, 0.00, '2025-01-22'),
(29, 10, 2, 0.00, '2025-01-22'),
(30, 10, 3, 0.00, '2025-01-22'),
(31, 11, 1, 0.00, '2025-01-22'),
(32, 11, 2, 0.00, '2025-01-22'),
(33, 11, 3, 0.00, '2025-01-22'),
(34, 12, 1, 0.00, '2025-01-22'),
(35, 12, 2, 0.00, '2025-01-22'),
(36, 12, 3, 0.00, '2025-01-22'),
(37, 13, 1, 0.00, '2025-01-22'),
(38, 13, 2, 0.00, '2025-01-22'),
(39, 13, 3, 0.00, '2025-01-22'),
(40, 1, 4, 0.00, '2025-01-22'),
(41, 1, 5, 0.00, '2025-01-22'),
(42, 1, 6, 0.00, '2025-01-22'),
(43, 2, 4, 0.00, '2025-01-22'),
(44, 2, 5, 0.00, '2025-01-22'),
(45, 2, 6, 0.00, '2025-01-22'),
(46, 3, 4, 0.00, '2025-01-22'),
(47, 3, 5, 0.00, '2025-01-22'),
(48, 3, 6, 0.00, '2025-01-22'),
(49, 4, 4, 0.00, '2025-01-22'),
(50, 4, 5, 0.00, '2025-01-22'),
(51, 4, 6, 0.00, '2025-01-22'),
(52, 5, 4, 0.00, '2025-01-22'),
(53, 5, 5, 0.00, '2025-01-22'),
(54, 5, 6, 0.00, '2025-01-22'),
(55, 6, 4, 0.00, '2025-01-22'),
(56, 6, 5, 0.00, '2025-01-22'),
(57, 6, 6, 0.00, '2025-01-22'),
(58, 7, 4, 0.00, '2025-01-22'),
(59, 7, 5, 0.00, '2025-01-22'),
(60, 7, 6, 0.00, '2025-01-22'),
(61, 8, 4, 0.00, '2025-01-22'),
(62, 8, 5, 0.00, '2025-01-22'),
(63, 8, 6, 0.00, '2025-01-22'),
(64, 9, 4, 0.00, '2025-01-22'),
(65, 9, 5, 0.00, '2025-01-22'),
(66, 9, 6, 0.00, '2025-01-22'),
(67, 10, 4, 0.00, '2025-01-22'),
(68, 10, 5, 0.00, '2025-01-22'),
(69, 10, 6, 0.00, '2025-01-22'),
(70, 11, 4, 0.00, '2025-01-22'),
(71, 11, 5, 0.00, '2025-01-22'),
(72, 11, 6, 0.00, '2025-01-22'),
(73, 12, 4, 0.00, '2025-01-22'),
(74, 12, 5, 0.00, '2025-01-22'),
(75, 12, 6, 0.00, '2025-01-22'),
(76, 13, 4, 0.00, '2025-01-22'),
(77, 13, 5, 0.00, '2025-01-22'),
(78, 13, 6, 0.00, '2025-01-22'),
(79, 1, 7, 0.00, '2025-01-22'),
(80, 1, 8, 0.00, '2025-01-22'),
(81, 1, 9, 0.00, '2025-01-22'),
(82, 2, 7, 0.00, '2025-01-22'),
(83, 2, 8, 0.00, '2025-01-22'),
(84, 2, 9, 0.00, '2025-01-22'),
(85, 3, 7, 0.00, '2025-01-22'),
(86, 3, 8, 0.00, '2025-01-22'),
(87, 3, 9, 0.00, '2025-01-22'),
(88, 4, 7, 0.00, '2025-01-22'),
(89, 4, 8, 0.00, '2025-01-22'),
(90, 4, 9, 0.00, '2025-01-22'),
(91, 5, 7, 0.00, '2025-01-22'),
(92, 5, 8, 0.00, '2025-01-22'),
(93, 5, 9, 0.00, '2025-01-22'),
(94, 6, 7, 0.00, '2025-01-22'),
(95, 6, 8, 0.00, '2025-01-22'),
(96, 6, 9, 0.00, '2025-01-22'),
(97, 7, 7, 0.00, '2025-01-22'),
(98, 7, 8, 0.00, '2025-01-22'),
(99, 7, 9, 0.00, '2025-01-22'),
(100, 8, 7, 0.00, '2025-01-22'),
(101, 8, 8, 0.00, '2025-01-22'),
(102, 8, 9, 0.00, '2025-01-22'),
(103, 9, 7, 0.00, '2025-01-22'),
(104, 9, 8, 0.00, '2025-01-22'),
(105, 9, 9, 0.00, '2025-01-22'),
(106, 10, 7, 0.00, '2025-01-22'),
(107, 10, 8, 0.00, '2025-01-22'),
(108, 10, 9, 0.00, '2025-01-22'),
(109, 11, 7, 0.00, '2025-01-22'),
(110, 11, 8, 0.00, '2025-01-22'),
(111, 11, 9, 0.00, '2025-01-22'),
(112, 12, 7, 0.00, '2025-01-22'),
(113, 12, 8, 0.00, '2025-01-22'),
(114, 12, 9, 0.00, '2025-01-22'),
(115, 13, 7, 0.00, '2025-01-22'),
(116, 13, 8, 0.00, '2025-01-22'),
(117, 13, 9, 0.00, '2025-01-22'),
(118, 1, 10, 0.00, '2025-01-22'),
(119, 1, 11, 0.00, '2025-01-22'),
(120, 1, 12, 0.00, '2025-01-22'),
(121, 2, 10, 0.00, '2025-01-22'),
(122, 2, 11, 0.00, '2025-01-22'),
(123, 2, 12, 0.00, '2025-01-22'),
(124, 3, 10, 0.00, '2025-01-22'),
(125, 3, 11, 0.00, '2025-01-22'),
(126, 3, 12, 0.00, '2025-01-22'),
(127, 4, 10, 0.00, '2025-01-22'),
(128, 4, 11, 0.00, '2025-01-22'),
(129, 4, 12, 0.00, '2025-01-22'),
(130, 5, 10, 0.00, '2025-01-22'),
(131, 5, 11, 0.00, '2025-01-22'),
(132, 5, 12, 0.00, '2025-01-22'),
(133, 6, 10, 0.00, '2025-01-22'),
(134, 6, 11, 0.00, '2025-01-22'),
(135, 6, 12, 0.00, '2025-01-22'),
(136, 7, 10, 0.00, '2025-01-22'),
(137, 7, 11, 0.00, '2025-01-22'),
(138, 7, 12, 0.00, '2025-01-22'),
(139, 8, 10, 0.00, '2025-01-22'),
(140, 8, 11, 0.00, '2025-01-22'),
(141, 8, 12, 0.00, '2025-01-22'),
(142, 9, 10, 0.00, '2025-01-22'),
(143, 9, 11, 0.00, '2025-01-22'),
(144, 9, 12, 0.00, '2025-01-22'),
(145, 10, 10, 0.00, '2025-01-22'),
(146, 10, 11, 0.00, '2025-01-22'),
(147, 10, 12, 0.00, '2025-01-22'),
(148, 11, 10, 0.00, '2025-01-22'),
(149, 11, 11, 0.00, '2025-01-22'),
(150, 11, 12, 0.00, '2025-01-22'),
(151, 12, 10, 0.00, '2025-01-22'),
(152, 12, 11, 0.00, '2025-01-22'),
(153, 12, 12, 0.00, '2025-01-22'),
(154, 13, 10, 0.00, '2025-01-22'),
(155, 13, 11, 0.00, '2025-01-22'),
(156, 13, 12, 0.00, '2025-01-22'),
(157, 14, 1, 0.00, '2025-01-22'),
(158, 14, 2, 0.00, '2025-01-22'),
(159, 14, 3, 0.00, '2025-01-22'),
(160, 15, 1, 0.00, '2025-01-22'),
(161, 15, 2, 0.00, '2025-01-22'),
(162, 15, 3, 0.00, '2025-01-22'),
(163, 16, 1, 0.00, '2025-01-22'),
(164, 16, 2, 0.00, '2025-01-22'),
(165, 16, 3, 0.00, '2025-01-22'),
(166, 17, 1, 0.00, '2025-01-22'),
(167, 17, 2, 0.00, '2025-01-22'),
(168, 17, 3, 0.00, '2025-01-22'),
(169, 18, 1, 0.00, '2025-01-22'),
(170, 18, 2, 0.00, '2025-01-22'),
(171, 18, 3, 0.00, '2025-01-22'),
(172, 19, 1, 0.00, '2025-01-22'),
(173, 19, 2, 0.00, '2025-01-22'),
(174, 19, 3, 0.00, '2025-01-22'),
(175, 20, 1, 0.00, '2025-01-22'),
(176, 20, 2, 0.00, '2025-01-22'),
(177, 20, 3, 0.00, '2025-01-22'),
(178, 21, 1, 0.00, '2025-01-22'),
(179, 21, 2, 0.00, '2025-01-22'),
(180, 21, 3, 0.00, '2025-01-22'),
(181, 22, 1, 0.00, '2025-01-22'),
(182, 22, 2, 0.00, '2025-01-22'),
(183, 22, 3, 0.00, '2025-01-22'),
(184, 23, 1, 0.00, '2025-01-22'),
(185, 23, 2, 0.00, '2025-01-22'),
(186, 23, 3, 0.00, '2025-01-22'),
(187, 24, 1, 0.00, '2025-01-22'),
(188, 24, 2, 0.00, '2025-01-22'),
(189, 24, 3, 0.00, '2025-01-22'),
(190, 25, 1, 0.00, '2025-01-22'),
(191, 25, 2, 0.00, '2025-01-22'),
(192, 25, 3, 0.00, '2025-01-22'),
(193, 26, 1, 0.00, '2025-01-22'),
(194, 26, 2, 0.00, '2025-01-22'),
(195, 26, 3, 0.00, '2025-01-22'),
(196, 14, 4, 0.00, '2025-01-22'),
(197, 14, 5, 0.00, '2025-01-22'),
(198, 14, 6, 0.00, '2025-01-22'),
(199, 15, 4, 0.00, '2025-01-22'),
(200, 15, 5, 0.00, '2025-01-22'),
(201, 15, 6, 0.00, '2025-01-22'),
(202, 16, 4, 0.00, '2025-01-22'),
(203, 16, 5, 0.00, '2025-01-22'),
(204, 16, 6, 0.00, '2025-01-22'),
(205, 17, 4, 0.00, '2025-01-22'),
(206, 17, 5, 0.00, '2025-01-22'),
(207, 17, 6, 0.00, '2025-01-22'),
(208, 18, 4, 0.00, '2025-01-22'),
(209, 18, 5, 0.00, '2025-01-22'),
(210, 18, 6, 0.00, '2025-01-22'),
(211, 19, 4, 0.00, '2025-01-22'),
(212, 19, 5, 0.00, '2025-01-22'),
(213, 19, 6, 0.00, '2025-01-22'),
(214, 20, 4, 0.00, '2025-01-22'),
(215, 20, 5, 0.00, '2025-01-22'),
(216, 20, 6, 0.00, '2025-01-22'),
(217, 21, 4, 0.00, '2025-01-22'),
(218, 21, 5, 0.00, '2025-01-22'),
(219, 21, 6, 0.00, '2025-01-22'),
(220, 22, 4, 0.00, '2025-01-22'),
(221, 22, 5, 0.00, '2025-01-22'),
(222, 22, 6, 0.00, '2025-01-22'),
(223, 23, 4, 0.00, '2025-01-22'),
(224, 23, 5, 0.00, '2025-01-22'),
(225, 23, 6, 0.00, '2025-01-22'),
(226, 24, 4, 0.00, '2025-01-22'),
(227, 24, 5, 0.00, '2025-01-22'),
(228, 24, 6, 0.00, '2025-01-22'),
(229, 25, 4, 0.00, '2025-01-22'),
(230, 25, 5, 0.00, '2025-01-22'),
(231, 25, 6, 0.00, '2025-01-22'),
(232, 26, 4, 0.00, '2025-01-22'),
(233, 26, 5, 0.00, '2025-01-22'),
(234, 26, 6, 0.00, '2025-01-22'),
(235, 14, 7, 0.00, '2025-01-22'),
(236, 14, 8, 0.00, '2025-01-22'),
(237, 14, 9, 0.00, '2025-01-22'),
(238, 15, 7, 0.00, '2025-01-22'),
(239, 15, 8, 0.00, '2025-01-22'),
(240, 15, 9, 0.00, '2025-01-22'),
(241, 16, 7, 0.00, '2025-01-22'),
(242, 16, 8, 0.00, '2025-01-22'),
(243, 16, 9, 0.00, '2025-01-22'),
(244, 17, 7, 0.00, '2025-01-22'),
(245, 17, 8, 0.00, '2025-01-22'),
(246, 17, 9, 0.00, '2025-01-22'),
(247, 18, 7, 0.00, '2025-01-22'),
(248, 18, 8, 0.00, '2025-01-22'),
(249, 18, 9, 0.00, '2025-01-22'),
(250, 19, 7, 0.00, '2025-01-22'),
(251, 19, 8, 0.00, '2025-01-22'),
(252, 19, 9, 0.00, '2025-01-22'),
(253, 20, 7, 0.00, '2025-01-22'),
(254, 20, 8, 0.00, '2025-01-22'),
(255, 20, 9, 0.00, '2025-01-22'),
(256, 21, 7, 0.00, '2025-01-22'),
(257, 21, 8, 0.00, '2025-01-22'),
(258, 21, 9, 0.00, '2025-01-22'),
(259, 22, 7, 0.00, '2025-01-22'),
(260, 22, 8, 0.00, '2025-01-22'),
(261, 22, 9, 0.00, '2025-01-22'),
(262, 23, 7, 0.00, '2025-01-22'),
(263, 23, 8, 0.00, '2025-01-22'),
(264, 23, 9, 0.00, '2025-01-22'),
(265, 24, 7, 0.00, '2025-01-22'),
(266, 24, 8, 0.00, '2025-01-22'),
(267, 24, 9, 0.00, '2025-01-22'),
(268, 25, 7, 0.00, '2025-01-22'),
(269, 25, 8, 0.00, '2025-01-22'),
(270, 25, 9, 0.00, '2025-01-22'),
(271, 26, 7, 0.00, '2025-01-22'),
(272, 26, 8, 0.00, '2025-01-22'),
(273, 26, 9, 0.00, '2025-01-22'),
(274, 14, 10, 0.00, '2025-01-22'),
(275, 14, 11, 0.00, '2025-01-22'),
(276, 14, 12, 0.00, '2025-01-22'),
(277, 15, 10, 0.00, '2025-01-22'),
(278, 15, 11, 0.00, '2025-01-22'),
(279, 15, 12, 0.00, '2025-01-22'),
(280, 16, 10, 0.00, '2025-01-22'),
(281, 16, 11, 0.00, '2025-01-22'),
(282, 16, 12, 0.00, '2025-01-22'),
(283, 17, 10, 0.00, '2025-01-22'),
(284, 17, 11, 0.00, '2025-01-22'),
(285, 17, 12, 0.00, '2025-01-22'),
(286, 18, 10, 0.00, '2025-01-22'),
(287, 18, 11, 0.00, '2025-01-22'),
(288, 18, 12, 0.00, '2025-01-22'),
(289, 19, 10, 0.00, '2025-01-22'),
(290, 19, 11, 0.00, '2025-01-22'),
(291, 19, 12, 0.00, '2025-01-22'),
(292, 20, 10, 0.00, '2025-01-22'),
(293, 20, 11, 0.00, '2025-01-22'),
(294, 20, 12, 0.00, '2025-01-22'),
(295, 21, 10, 0.00, '2025-01-22'),
(296, 21, 11, 0.00, '2025-01-22'),
(297, 21, 12, 0.00, '2025-01-22'),
(298, 22, 10, 0.00, '2025-01-22'),
(299, 22, 11, 0.00, '2025-01-22'),
(300, 22, 12, 0.00, '2025-01-22'),
(301, 23, 10, 0.00, '2025-01-22'),
(302, 23, 11, 0.00, '2025-01-22'),
(303, 23, 12, 0.00, '2025-01-22'),
(304, 24, 10, 0.00, '2025-01-22'),
(305, 24, 11, 0.00, '2025-01-22'),
(306, 24, 12, 0.00, '2025-01-22'),
(307, 25, 10, 0.00, '2025-01-22'),
(308, 25, 11, 0.00, '2025-01-22'),
(309, 25, 12, 0.00, '2025-01-22'),
(310, 26, 10, 0.00, '2025-01-22'),
(311, 26, 11, 0.00, '2025-01-22'),
(312, 26, 12, 0.00, '2025-01-22'),
(313, 27, 1, 0.00, '2025-01-22'),
(314, 27, 2, 0.00, '2025-01-22'),
(315, 27, 3, 0.00, '2025-01-22'),
(316, 28, 1, 0.00, '2025-01-22'),
(317, 28, 2, 0.00, '2025-01-22'),
(318, 28, 3, 0.00, '2025-01-22'),
(319, 29, 1, 0.00, '2025-01-22'),
(320, 29, 2, 0.00, '2025-01-22'),
(321, 29, 3, 0.00, '2025-01-22'),
(322, 30, 1, 0.00, '2025-01-22'),
(323, 30, 2, 0.00, '2025-01-22'),
(324, 30, 3, 0.00, '2025-01-22'),
(325, 31, 1, 0.00, '2025-01-22'),
(326, 31, 2, 0.00, '2025-01-22'),
(327, 31, 3, 0.00, '2025-01-22'),
(328, 32, 1, 0.00, '2025-01-22'),
(329, 32, 2, 0.00, '2025-01-22'),
(330, 32, 3, 0.00, '2025-01-22'),
(331, 33, 1, 0.00, '2025-01-22'),
(332, 33, 2, 0.00, '2025-01-22'),
(333, 33, 3, 0.00, '2025-01-22'),
(334, 34, 1, 0.00, '2025-01-22'),
(335, 34, 2, 0.00, '2025-01-22'),
(336, 34, 3, 0.00, '2025-01-22'),
(337, 35, 1, 0.00, '2025-01-22'),
(338, 35, 2, 0.00, '2025-01-22'),
(339, 35, 3, 0.00, '2025-01-22'),
(340, 36, 1, 0.00, '2025-01-22'),
(341, 36, 2, 0.00, '2025-01-22'),
(342, 36, 3, 0.00, '2025-01-22'),
(343, 37, 1, 0.00, '2025-01-22'),
(344, 37, 2, 0.00, '2025-01-22'),
(345, 37, 3, 0.00, '2025-01-22'),
(346, 38, 1, 0.00, '2025-01-22'),
(347, 38, 2, 0.00, '2025-01-22'),
(348, 38, 3, 0.00, '2025-01-22'),
(349, 39, 1, 0.00, '2025-01-22'),
(350, 39, 2, 0.00, '2025-01-22'),
(351, 39, 3, 0.00, '2025-01-22'),
(352, 27, 4, 0.00, '2025-01-22'),
(353, 27, 5, 0.00, '2025-01-22'),
(354, 27, 6, 0.00, '2025-01-22'),
(355, 28, 4, 0.00, '2025-01-22'),
(356, 28, 5, 0.00, '2025-01-22'),
(357, 28, 6, 0.00, '2025-01-22'),
(358, 29, 4, 0.00, '2025-01-22'),
(359, 29, 5, 0.00, '2025-01-22'),
(360, 29, 6, 0.00, '2025-01-22'),
(361, 30, 4, 0.00, '2025-01-22'),
(362, 30, 5, 0.00, '2025-01-22'),
(363, 30, 6, 0.00, '2025-01-22'),
(364, 31, 4, 0.00, '2025-01-22'),
(365, 31, 5, 0.00, '2025-01-22'),
(366, 31, 6, 0.00, '2025-01-22'),
(367, 32, 4, 0.00, '2025-01-22'),
(368, 32, 5, 0.00, '2025-01-22'),
(369, 32, 6, 0.00, '2025-01-22'),
(370, 33, 4, 0.00, '2025-01-22'),
(371, 33, 5, 0.00, '2025-01-22'),
(372, 33, 6, 0.00, '2025-01-22'),
(373, 34, 4, 0.00, '2025-01-22'),
(374, 34, 5, 0.00, '2025-01-22'),
(375, 34, 6, 0.00, '2025-01-22'),
(376, 35, 4, 0.00, '2025-01-22'),
(377, 35, 5, 0.00, '2025-01-22'),
(378, 35, 6, 0.00, '2025-01-22'),
(379, 36, 4, 0.00, '2025-01-22'),
(380, 36, 5, 0.00, '2025-01-22'),
(381, 36, 6, 0.00, '2025-01-22'),
(382, 37, 4, 0.00, '2025-01-22'),
(383, 37, 5, 0.00, '2025-01-22'),
(384, 37, 6, 0.00, '2025-01-22'),
(385, 38, 4, 0.00, '2025-01-22'),
(386, 38, 5, 0.00, '2025-01-22'),
(387, 38, 6, 0.00, '2025-01-22'),
(388, 39, 4, 0.00, '2025-01-22'),
(389, 39, 5, 0.00, '2025-01-22'),
(390, 39, 6, 0.00, '2025-01-22'),
(391, 27, 7, 0.00, '2025-01-22'),
(392, 27, 8, 0.00, '2025-01-22'),
(393, 27, 9, 0.00, '2025-01-22'),
(394, 28, 7, 0.00, '2025-01-22'),
(395, 28, 8, 0.00, '2025-01-22'),
(396, 28, 9, 0.00, '2025-01-22'),
(397, 29, 7, 0.00, '2025-01-22'),
(398, 29, 8, 0.00, '2025-01-22'),
(399, 29, 9, 0.00, '2025-01-22'),
(400, 30, 7, 0.00, '2025-01-22'),
(401, 30, 8, 0.00, '2025-01-22'),
(402, 30, 9, 0.00, '2025-01-22'),
(403, 31, 7, 0.00, '2025-01-22'),
(404, 31, 8, 0.00, '2025-01-22'),
(405, 31, 9, 0.00, '2025-01-22'),
(406, 32, 7, 0.00, '2025-01-22'),
(407, 32, 8, 0.00, '2025-01-22'),
(408, 32, 9, 0.00, '2025-01-22'),
(409, 33, 7, 0.00, '2025-01-22'),
(410, 33, 8, 0.00, '2025-01-22'),
(411, 33, 9, 0.00, '2025-01-22'),
(412, 34, 7, 0.00, '2025-01-22'),
(413, 34, 8, 0.00, '2025-01-22'),
(414, 34, 9, 0.00, '2025-01-22'),
(415, 35, 7, 0.00, '2025-01-22'),
(416, 35, 8, 0.00, '2025-01-22'),
(417, 35, 9, 0.00, '2025-01-22'),
(418, 36, 7, 0.00, '2025-01-22'),
(419, 36, 8, 0.00, '2025-01-22'),
(420, 36, 9, 0.00, '2025-01-22'),
(421, 37, 7, 0.00, '2025-01-22'),
(422, 37, 8, 0.00, '2025-01-22'),
(423, 37, 9, 0.00, '2025-01-22'),
(424, 38, 7, 0.00, '2025-01-22'),
(425, 38, 8, 0.00, '2025-01-22'),
(426, 38, 9, 0.00, '2025-01-22'),
(427, 39, 7, 0.00, '2025-01-22'),
(428, 39, 8, 0.00, '2025-01-22'),
(429, 39, 9, 0.00, '2025-01-22'),
(430, 27, 10, 0.00, '2025-01-22'),
(431, 27, 11, 0.00, '2025-01-22'),
(432, 27, 12, 0.00, '2025-01-22'),
(433, 28, 10, 0.00, '2025-01-22'),
(434, 28, 11, 0.00, '2025-01-22'),
(435, 28, 12, 0.00, '2025-01-22'),
(436, 29, 10, 0.00, '2025-01-22'),
(437, 29, 11, 0.00, '2025-01-22'),
(438, 29, 12, 0.00, '2025-01-22'),
(439, 30, 10, 0.00, '2025-01-22'),
(440, 30, 11, 0.00, '2025-01-22'),
(441, 30, 12, 0.00, '2025-01-22'),
(442, 31, 10, 0.00, '2025-01-22'),
(443, 31, 11, 0.00, '2025-01-22'),
(444, 31, 12, 0.00, '2025-01-22'),
(445, 32, 10, 0.00, '2025-01-22'),
(446, 32, 11, 0.00, '2025-01-22'),
(447, 32, 12, 0.00, '2025-01-22'),
(448, 33, 10, 0.00, '2025-01-22'),
(449, 33, 11, 0.00, '2025-01-22'),
(450, 33, 12, 0.00, '2025-01-22'),
(451, 34, 10, 0.00, '2025-01-22'),
(452, 34, 11, 0.00, '2025-01-22'),
(453, 34, 12, 0.00, '2025-01-22'),
(454, 35, 10, 0.00, '2025-01-22'),
(455, 35, 11, 0.00, '2025-01-22'),
(456, 35, 12, 0.00, '2025-01-22'),
(457, 36, 10, 0.00, '2025-01-22'),
(458, 36, 11, 0.00, '2025-01-22'),
(459, 36, 12, 0.00, '2025-01-22'),
(460, 37, 10, 0.00, '2025-01-22'),
(461, 37, 11, 0.00, '2025-01-22'),
(462, 37, 12, 0.00, '2025-01-22'),
(463, 38, 10, 0.00, '2025-01-22'),
(464, 38, 11, 0.00, '2025-01-22'),
(465, 38, 12, 0.00, '2025-01-22'),
(466, 39, 10, 0.00, '2025-01-22'),
(467, 39, 11, 0.00, '2025-01-22'),
(468, 39, 12, 0.00, '2025-01-22'),
(469, 40, 1, 0.00, '2025-01-22'),
(470, 40, 2, 0.00, '2025-01-22'),
(471, 40, 3, 0.00, '2025-01-22'),
(472, 41, 1, 0.00, '2025-01-22'),
(473, 41, 2, 0.00, '2025-01-22'),
(474, 41, 3, 0.00, '2025-01-22'),
(475, 42, 1, 0.00, '2025-01-22'),
(476, 42, 2, 0.00, '2025-01-22'),
(477, 42, 3, 0.00, '2025-01-22'),
(478, 43, 1, 0.00, '2025-01-22'),
(479, 43, 2, 0.00, '2025-01-22'),
(480, 43, 3, 0.00, '2025-01-22'),
(481, 44, 1, 0.00, '2025-01-22'),
(482, 44, 2, 0.00, '2025-01-22'),
(483, 44, 3, 0.00, '2025-01-22'),
(484, 45, 1, 0.00, '2025-01-22'),
(485, 45, 2, 0.00, '2025-01-22'),
(486, 45, 3, 0.00, '2025-01-22'),
(487, 46, 1, 0.00, '2025-01-22'),
(488, 46, 2, 0.00, '2025-01-22'),
(489, 46, 3, 0.00, '2025-01-22'),
(490, 47, 1, 0.00, '2025-01-22'),
(491, 47, 2, 0.00, '2025-01-22'),
(492, 47, 3, 0.00, '2025-01-22'),
(493, 48, 1, 0.00, '2025-01-22'),
(494, 48, 2, 0.00, '2025-01-22'),
(495, 48, 3, 0.00, '2025-01-22'),
(496, 49, 1, 0.00, '2025-01-22'),
(497, 49, 2, 0.00, '2025-01-22'),
(498, 49, 3, 0.00, '2025-01-22'),
(499, 50, 1, 0.00, '2025-01-22'),
(500, 50, 2, 0.00, '2025-01-22'),
(501, 50, 3, 0.00, '2025-01-22'),
(502, 51, 1, 0.00, '2025-01-22'),
(503, 51, 2, 0.00, '2025-01-22'),
(504, 51, 3, 0.00, '2025-01-22'),
(505, 52, 1, 0.00, '2025-01-22'),
(506, 52, 2, 0.00, '2025-01-22'),
(507, 52, 3, 0.00, '2025-01-22'),
(508, 40, 4, 0.00, '2025-01-22'),
(509, 40, 5, 0.00, '2025-01-22'),
(510, 40, 6, 0.00, '2025-01-22'),
(511, 41, 4, 0.00, '2025-01-22'),
(512, 41, 5, 0.00, '2025-01-22'),
(513, 41, 6, 0.00, '2025-01-22'),
(514, 42, 4, 0.00, '2025-01-22'),
(515, 42, 5, 0.00, '2025-01-22'),
(516, 42, 6, 0.00, '2025-01-22'),
(517, 43, 4, 0.00, '2025-01-22'),
(518, 43, 5, 0.00, '2025-01-22'),
(519, 43, 6, 0.00, '2025-01-22'),
(520, 44, 4, 0.00, '2025-01-22'),
(521, 44, 5, 0.00, '2025-01-22'),
(522, 44, 6, 0.00, '2025-01-22'),
(523, 45, 4, 0.00, '2025-01-22'),
(524, 45, 5, 0.00, '2025-01-22'),
(525, 45, 6, 0.00, '2025-01-22'),
(526, 46, 4, 0.00, '2025-01-22'),
(527, 46, 5, 0.00, '2025-01-22'),
(528, 46, 6, 0.00, '2025-01-22'),
(529, 47, 4, 0.00, '2025-01-22'),
(530, 47, 5, 0.00, '2025-01-22'),
(531, 47, 6, 0.00, '2025-01-22'),
(532, 48, 4, 0.00, '2025-01-22'),
(533, 48, 5, 0.00, '2025-01-22'),
(534, 48, 6, 0.00, '2025-01-22'),
(535, 49, 4, 0.00, '2025-01-22'),
(536, 49, 5, 0.00, '2025-01-22'),
(537, 49, 6, 0.00, '2025-01-22'),
(538, 50, 4, 0.00, '2025-01-22'),
(539, 50, 5, 0.00, '2025-01-22'),
(540, 50, 6, 0.00, '2025-01-22'),
(541, 51, 4, 0.00, '2025-01-22'),
(542, 51, 5, 0.00, '2025-01-22'),
(543, 51, 6, 0.00, '2025-01-22'),
(544, 52, 4, 0.00, '2025-01-22'),
(545, 52, 5, 0.00, '2025-01-22'),
(546, 52, 6, 0.00, '2025-01-22'),
(547, 40, 7, 0.00, '2025-01-22'),
(548, 40, 8, 0.00, '2025-01-22'),
(549, 40, 9, 0.00, '2025-01-22'),
(550, 41, 7, 0.00, '2025-01-22'),
(551, 41, 8, 0.00, '2025-01-22'),
(552, 41, 9, 0.00, '2025-01-22'),
(553, 42, 7, 0.00, '2025-01-22'),
(554, 42, 8, 0.00, '2025-01-22'),
(555, 42, 9, 0.00, '2025-01-22'),
(556, 43, 7, 0.00, '2025-01-22'),
(557, 43, 8, 0.00, '2025-01-22'),
(558, 43, 9, 0.00, '2025-01-22'),
(559, 44, 7, 0.00, '2025-01-22'),
(560, 44, 8, 0.00, '2025-01-22'),
(561, 44, 9, 0.00, '2025-01-22'),
(562, 45, 7, 0.00, '2025-01-22'),
(563, 45, 8, 0.00, '2025-01-22'),
(564, 45, 9, 0.00, '2025-01-22'),
(565, 46, 7, 0.00, '2025-01-22'),
(566, 46, 8, 0.00, '2025-01-22'),
(567, 46, 9, 0.00, '2025-01-22'),
(568, 47, 7, 0.00, '2025-01-22'),
(569, 47, 8, 0.00, '2025-01-22'),
(570, 47, 9, 0.00, '2025-01-22'),
(571, 48, 7, 0.00, '2025-01-22'),
(572, 48, 8, 0.00, '2025-01-22'),
(573, 48, 9, 0.00, '2025-01-22'),
(574, 49, 7, 0.00, '2025-01-22'),
(575, 49, 8, 0.00, '2025-01-22'),
(576, 49, 9, 0.00, '2025-01-22'),
(577, 50, 7, 0.00, '2025-01-22'),
(578, 50, 8, 0.00, '2025-01-22'),
(579, 50, 9, 0.00, '2025-01-22'),
(580, 51, 7, 0.00, '2025-01-22'),
(581, 51, 8, 0.00, '2025-01-22'),
(582, 51, 9, 0.00, '2025-01-22'),
(583, 52, 7, 0.00, '2025-01-22'),
(584, 52, 8, 0.00, '2025-01-22'),
(585, 52, 9, 0.00, '2025-01-22'),
(586, 40, 10, 0.00, '2025-01-22'),
(587, 40, 11, 0.00, '2025-01-22'),
(588, 40, 12, 0.00, '2025-01-22'),
(589, 41, 10, 0.00, '2025-01-22'),
(590, 41, 11, 0.00, '2025-01-22'),
(591, 41, 12, 0.00, '2025-01-22'),
(592, 42, 10, 0.00, '2025-01-22'),
(593, 42, 11, 0.00, '2025-01-22'),
(594, 42, 12, 0.00, '2025-01-22'),
(595, 43, 10, 0.00, '2025-01-22'),
(596, 43, 11, 0.00, '2025-01-22'),
(597, 43, 12, 0.00, '2025-01-22'),
(598, 44, 10, 0.00, '2025-01-22'),
(599, 44, 11, 0.00, '2025-01-22'),
(600, 44, 12, 0.00, '2025-01-22'),
(601, 45, 10, 0.00, '2025-01-22'),
(602, 45, 11, 0.00, '2025-01-22'),
(603, 45, 12, 0.00, '2025-01-22'),
(604, 46, 10, 0.00, '2025-01-22'),
(605, 46, 11, 0.00, '2025-01-22'),
(606, 46, 12, 0.00, '2025-01-22'),
(607, 47, 10, 0.00, '2025-01-22'),
(608, 47, 11, 0.00, '2025-01-22'),
(609, 47, 12, 0.00, '2025-01-22'),
(610, 48, 10, 0.00, '2025-01-22'),
(611, 48, 11, 0.00, '2025-01-22'),
(612, 48, 12, 0.00, '2025-01-22'),
(613, 49, 10, 0.00, '2025-01-22'),
(614, 49, 11, 0.00, '2025-01-22'),
(615, 49, 12, 0.00, '2025-01-22'),
(616, 50, 10, 0.00, '2025-01-22'),
(617, 50, 11, 0.00, '2025-01-22'),
(618, 50, 12, 0.00, '2025-01-22'),
(619, 51, 10, 0.00, '2025-01-22'),
(620, 51, 11, 0.00, '2025-01-22'),
(621, 51, 12, 0.00, '2025-01-22'),
(622, 52, 10, 0.00, '2025-01-22'),
(623, 52, 11, 0.00, '2025-01-22'),
(624, 52, 12, 0.00, '2025-01-22'),
(625, 53, 1, 0.00, '2025-01-22'),
(626, 53, 2, 0.00, '2025-01-22'),
(627, 53, 3, 0.00, '2025-01-22'),
(628, 54, 1, 0.00, '2025-01-22'),
(629, 54, 2, 0.00, '2025-01-22'),
(630, 54, 3, 0.00, '2025-01-22'),
(631, 55, 1, 0.00, '2025-01-22'),
(632, 55, 2, 0.00, '2025-01-22'),
(633, 55, 3, 0.00, '2025-01-22'),
(634, 56, 1, 0.00, '2025-01-22'),
(635, 56, 2, 0.00, '2025-01-22'),
(636, 56, 3, 0.00, '2025-01-22'),
(637, 57, 1, 0.00, '2025-01-22'),
(638, 57, 2, 0.00, '2025-01-22'),
(639, 57, 3, 0.00, '2025-01-22'),
(640, 58, 1, 0.00, '2025-01-22'),
(641, 58, 2, 0.00, '2025-01-22'),
(642, 58, 3, 0.00, '2025-01-22'),
(643, 59, 1, 0.00, '2025-01-22'),
(644, 59, 2, 0.00, '2025-01-22'),
(645, 59, 3, 0.00, '2025-01-22'),
(646, 60, 1, 0.00, '2025-01-22'),
(647, 60, 2, 0.00, '2025-01-22'),
(648, 60, 3, 0.00, '2025-01-22'),
(649, 61, 1, 0.00, '2025-01-22'),
(650, 61, 2, 0.00, '2025-01-22'),
(651, 61, 3, 0.00, '2025-01-22'),
(652, 62, 1, 0.00, '2025-01-22'),
(653, 62, 2, 0.00, '2025-01-22'),
(654, 62, 3, 0.00, '2025-01-22'),
(655, 63, 1, 0.00, '2025-01-22'),
(656, 63, 2, 0.00, '2025-01-22'),
(657, 63, 3, 0.00, '2025-01-22'),
(658, 64, 1, 0.00, '2025-01-22'),
(659, 64, 2, 0.00, '2025-01-22'),
(660, 64, 3, 0.00, '2025-01-22'),
(661, 65, 1, 0.00, '2025-01-22'),
(662, 65, 2, 0.00, '2025-01-22'),
(663, 65, 3, 0.00, '2025-01-22'),
(664, 53, 4, 0.00, '2025-01-22'),
(665, 53, 5, 0.00, '2025-01-22'),
(666, 53, 6, 0.00, '2025-01-22'),
(667, 54, 4, 0.00, '2025-01-22'),
(668, 54, 5, 0.00, '2025-01-22'),
(669, 54, 6, 0.00, '2025-01-22'),
(670, 55, 4, 0.00, '2025-01-22'),
(671, 55, 5, 0.00, '2025-01-22'),
(672, 55, 6, 0.00, '2025-01-22'),
(673, 56, 4, 0.00, '2025-01-22'),
(674, 56, 5, 0.00, '2025-01-22'),
(675, 56, 6, 0.00, '2025-01-22'),
(676, 57, 4, 0.00, '2025-01-22'),
(677, 57, 5, 0.00, '2025-01-22'),
(678, 57, 6, 0.00, '2025-01-22'),
(679, 58, 4, 0.00, '2025-01-22'),
(680, 58, 5, 0.00, '2025-01-22'),
(681, 58, 6, 0.00, '2025-01-22'),
(682, 59, 4, 0.00, '2025-01-22'),
(683, 59, 5, 0.00, '2025-01-22'),
(684, 59, 6, 0.00, '2025-01-22'),
(685, 60, 4, 0.00, '2025-01-22'),
(686, 60, 5, 0.00, '2025-01-22'),
(687, 60, 6, 0.00, '2025-01-22'),
(688, 61, 4, 0.00, '2025-01-22'),
(689, 61, 5, 0.00, '2025-01-22'),
(690, 61, 6, 0.00, '2025-01-22'),
(691, 62, 4, 0.00, '2025-01-22'),
(692, 62, 5, 0.00, '2025-01-22'),
(693, 62, 6, 0.00, '2025-01-22'),
(694, 63, 4, 0.00, '2025-01-22'),
(695, 63, 5, 0.00, '2025-01-22'),
(696, 63, 6, 0.00, '2025-01-22'),
(697, 64, 4, 0.00, '2025-01-22'),
(698, 64, 5, 0.00, '2025-01-22'),
(699, 64, 6, 0.00, '2025-01-22'),
(700, 65, 4, 0.00, '2025-01-22'),
(701, 65, 5, 0.00, '2025-01-22'),
(702, 65, 6, 0.00, '2025-01-22'),
(703, 53, 7, 0.00, '2025-01-22'),
(704, 53, 8, 0.00, '2025-01-22'),
(705, 53, 9, 0.00, '2025-01-22'),
(706, 54, 7, 0.00, '2025-01-22'),
(707, 54, 8, 0.00, '2025-01-22'),
(708, 54, 9, 0.00, '2025-01-22'),
(709, 55, 7, 0.00, '2025-01-22'),
(710, 55, 8, 0.00, '2025-01-22'),
(711, 55, 9, 0.00, '2025-01-22'),
(712, 56, 7, 0.00, '2025-01-22'),
(713, 56, 8, 0.00, '2025-01-22'),
(714, 56, 9, 0.00, '2025-01-22'),
(715, 57, 7, 0.00, '2025-01-22'),
(716, 57, 8, 0.00, '2025-01-22'),
(717, 57, 9, 0.00, '2025-01-22'),
(718, 58, 7, 0.00, '2025-01-22'),
(719, 58, 8, 0.00, '2025-01-22'),
(720, 58, 9, 0.00, '2025-01-22'),
(721, 59, 7, 0.00, '2025-01-22'),
(722, 59, 8, 0.00, '2025-01-22'),
(723, 59, 9, 0.00, '2025-01-22'),
(724, 60, 7, 0.00, '2025-01-22'),
(725, 60, 8, 0.00, '2025-01-22'),
(726, 60, 9, 0.00, '2025-01-22'),
(727, 61, 7, 0.00, '2025-01-22'),
(728, 61, 8, 0.00, '2025-01-22'),
(729, 61, 9, 0.00, '2025-01-22'),
(730, 62, 7, 0.00, '2025-01-22'),
(731, 62, 8, 0.00, '2025-01-22'),
(732, 62, 9, 0.00, '2025-01-22'),
(733, 63, 7, 0.00, '2025-01-22'),
(734, 63, 8, 0.00, '2025-01-22'),
(735, 63, 9, 0.00, '2025-01-22'),
(736, 64, 7, 0.00, '2025-01-22'),
(737, 64, 8, 0.00, '2025-01-22'),
(738, 64, 9, 0.00, '2025-01-22'),
(739, 65, 7, 0.00, '2025-01-22'),
(740, 65, 8, 0.00, '2025-01-22'),
(741, 65, 9, 0.00, '2025-01-22'),
(742, 53, 10, 0.00, '2025-01-22'),
(743, 53, 11, 0.00, '2025-01-22'),
(744, 53, 12, 0.00, '2025-01-22'),
(745, 54, 10, 0.00, '2025-01-22'),
(746, 54, 11, 0.00, '2025-01-22'),
(747, 54, 12, 0.00, '2025-01-22'),
(748, 55, 10, 0.00, '2025-01-22'),
(749, 55, 11, 0.00, '2025-01-22'),
(750, 55, 12, 0.00, '2025-01-22'),
(751, 56, 10, 0.00, '2025-01-22'),
(752, 56, 11, 0.00, '2025-01-22'),
(753, 56, 12, 0.00, '2025-01-22'),
(754, 57, 10, 0.00, '2025-01-22'),
(755, 57, 11, 0.00, '2025-01-22'),
(756, 57, 12, 0.00, '2025-01-22'),
(757, 58, 10, 0.00, '2025-01-22'),
(758, 58, 11, 0.00, '2025-01-22'),
(759, 58, 12, 0.00, '2025-01-22'),
(760, 59, 10, 0.00, '2025-01-22'),
(761, 59, 11, 0.00, '2025-01-22'),
(762, 59, 12, 0.00, '2025-01-22'),
(763, 60, 10, 0.00, '2025-01-22'),
(764, 60, 11, 0.00, '2025-01-22'),
(765, 60, 12, 0.00, '2025-01-22'),
(766, 61, 10, 0.00, '2025-01-22'),
(767, 61, 11, 0.00, '2025-01-22'),
(768, 61, 12, 0.00, '2025-01-22'),
(769, 62, 10, 0.00, '2025-01-22'),
(770, 62, 11, 0.00, '2025-01-22'),
(771, 62, 12, 0.00, '2025-01-22'),
(772, 63, 10, 0.00, '2025-01-22'),
(773, 63, 11, 0.00, '2025-01-22'),
(774, 63, 12, 0.00, '2025-01-22'),
(775, 64, 10, 0.00, '2025-01-22'),
(776, 64, 11, 0.00, '2025-01-22'),
(777, 64, 12, 0.00, '2025-01-22'),
(778, 65, 10, 0.00, '2025-01-22'),
(779, 65, 11, 0.00, '2025-01-22'),
(780, 65, 12, 0.00, '2025-01-22'),
(781, 66, 1, 19.00, '2025-02-06'),
(782, 66, 2, 0.00, '2025-01-22'),
(783, 66, 3, 0.00, '2025-01-22'),
(784, 66, 4, 0.00, '2025-01-22'),
(785, 66, 5, 0.00, '2025-01-22'),
(786, 66, 6, 0.00, '2025-01-22'),
(787, 66, 7, 0.00, '2025-01-22'),
(788, 66, 8, 0.00, '2025-01-22'),
(789, 66, 9, 0.00, '2025-01-22'),
(790, 66, 10, 0.00, '2025-01-22'),
(791, 66, 11, 0.00, '2025-01-22'),
(792, 66, 12, 0.00, '2025-01-22'),
(1024, 128, 1, 0.00, '2025-01-22'),
(1025, 128, 2, 0.00, '2025-01-22'),
(1026, 128, 3, 0.00, '2025-01-22'),
(1027, 129, 1, 0.00, '2025-01-22'),
(1028, 129, 2, 0.00, '2025-01-22'),
(1029, 129, 3, 0.00, '2025-01-22'),
(1030, 130, 1, 0.00, '2025-01-22'),
(1031, 130, 2, 0.00, '2025-01-22'),
(1032, 130, 3, 0.00, '2025-01-22'),
(1033, 128, 4, 0.00, '2025-01-22'),
(1034, 128, 5, 0.00, '2025-01-22'),
(1035, 128, 6, 0.00, '2025-01-22'),
(1036, 129, 4, 0.00, '2025-01-22'),
(1037, 129, 5, 0.00, '2025-01-22'),
(1038, 129, 6, 0.00, '2025-01-22'),
(1039, 130, 4, 0.00, '2025-01-22'),
(1040, 130, 5, 0.00, '2025-01-22'),
(1041, 130, 6, 0.00, '2025-01-22'),
(1042, 128, 7, 0.00, '2025-01-22'),
(1043, 128, 8, 0.00, '2025-01-22'),
(1044, 128, 9, 0.00, '2025-01-22'),
(1045, 129, 7, 0.00, '2025-01-22'),
(1046, 129, 8, 0.00, '2025-01-22'),
(1047, 129, 9, 0.00, '2025-01-22'),
(1048, 130, 7, 0.00, '2025-01-22'),
(1049, 130, 8, 0.00, '2025-01-22'),
(1050, 130, 9, 0.00, '2025-01-22'),
(1051, 128, 10, 0.00, '2025-01-22'),
(1052, 128, 11, 0.00, '2025-01-22'),
(1053, 128, 12, 0.00, '2025-01-22'),
(1054, 129, 10, 0.00, '2025-01-22'),
(1055, 129, 11, 0.00, '2025-01-22'),
(1056, 129, 12, 0.00, '2025-01-22'),
(1057, 130, 10, 0.00, '2025-01-22'),
(1058, 130, 11, 0.00, '2025-01-22'),
(1059, 130, 12, 0.00, '2025-01-22'),
(1087, 131, 1, 0.00, '2025-01-22'),
(1088, 131, 2, 0.00, '2025-01-22'),
(1089, 131, 3, 0.00, '2025-01-22'),
(1090, 132, 1, 20.00, '2025-02-10'),
(1091, 132, 2, 10.00, '2025-02-10'),
(1092, 132, 3, 15.00, '2025-01-30'),
(1093, 133, 1, 0.00, '2025-01-22'),
(1094, 133, 2, 0.00, '2025-01-22'),
(1095, 133, 3, 0.00, '2025-01-22'),
(1096, 131, 4, 0.00, '2025-01-22'),
(1097, 131, 5, 0.00, '2025-01-22'),
(1098, 131, 6, 0.00, '2025-01-22'),
(1099, 132, 4, 10.00, '2025-01-29'),
(1100, 132, 5, 0.00, '2025-01-22'),
(1101, 132, 6, 0.00, '2025-01-22'),
(1102, 133, 4, 0.00, '2025-01-22'),
(1103, 133, 5, 0.00, '2025-01-22'),
(1104, 133, 6, 0.00, '2025-01-22'),
(1105, 131, 7, 0.00, '2025-01-22'),
(1106, 131, 8, 0.00, '2025-01-22'),
(1107, 131, 9, 0.00, '2025-01-22'),
(1108, 132, 7, 0.00, '2025-01-22'),
(1109, 132, 8, 0.00, '2025-01-22'),
(1110, 132, 9, 0.00, '2025-01-22'),
(1111, 133, 7, 0.00, '2025-01-22'),
(1112, 133, 8, 0.00, '2025-01-22'),
(1113, 133, 9, 0.00, '2025-01-22'),
(1114, 131, 10, 0.00, '2025-01-22'),
(1115, 131, 11, 0.00, '2025-01-22'),
(1116, 131, 12, 0.00, '2025-01-22'),
(1117, 132, 10, 0.00, '2025-01-22'),
(1118, 132, 11, 0.00, '2025-01-22'),
(1119, 132, 12, 0.00, '2025-01-22'),
(1120, 133, 10, 0.00, '2025-01-22'),
(1121, 133, 11, 0.00, '2025-01-22'),
(1122, 133, 12, 0.00, '2025-01-22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seccion`
--

CREATE TABLE `seccion` (
  `id_seccion` int(11) NOT NULL,
  `id_grado` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `limite_cupo` int(11) NOT NULL,
  `turno` enum('Mañana','Tarde','Noche') NOT NULL DEFAULT 'Mañana'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `seccion`
--

INSERT INTO `seccion` (`id_seccion`, `id_grado`, `nombre`, `limite_cupo`, `turno`) VALUES
(1, 1, 'A', 20, 'Mañana'),
(2, 1, 'B', 20, 'Mañana'),
(3, 1, 'C', 20, 'Mañana'),
(4, 2, 'A', 20, 'Mañana'),
(5, 2, 'B', 20, 'Mañana'),
(6, 3, 'A', 20, 'Mañana'),
(7, 3, 'B', 20, 'Mañana'),
(8, 4, 'Confianza', 20, 'Mañana'),
(9, 5, 'Respeto', 20, 'Mañana');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tema`
--

CREATE TABLE `tema` (
  `id_tema` int(11) NOT NULL,
  `id_etapa_planificacion` int(11) NOT NULL,
  `id_curso` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tema`
--

INSERT INTO `tema` (`id_tema`, `id_etapa_planificacion`, `id_curso`, `nombre`) VALUES
(1, 1, 1, 'Números Naturales'),
(2, 2, 1, 'Adición y Sustracción'),
(3, 3, 1, 'Multiplicación y División'),
(4, 4, 1, 'Fracciones'),
(5, 5, 1, 'Decimales'),
(6, 6, 1, 'Operaciones combinadas'),
(7, 7, 1, 'Sistema métrico decimal'),
(8, 8, 1, 'Unidades de longitud'),
(9, 9, 1, 'Unidades de masa'),
(10, 10, 1, 'Unidades de tiempo'),
(11, 11, 1, 'Ángulos básicos'),
(12, 12, 1, 'Perímetro y área'),
(13, 13, 1, 'Figuras geométricas'),
(14, 14, 1, 'Volumen y capacidad'),
(15, 15, 1, 'Introducción a álgebra'),
(16, 16, 1, 'Ecuaciones simples'),
(17, 17, 1, 'Proporciones'),
(18, 18, 1, 'Regla de tres simple'),
(19, 19, 1, 'Porcentajes'),
(20, 20, 1, 'Interés simple'),
(21, 21, 1, 'Probabilidad básica'),
(22, 22, 1, 'Gráficos estadísticos'),
(23, 23, 1, 'Promedios'),
(24, 24, 1, 'Mediana y moda'),
(25, 25, 1, 'Razones y proporciones'),
(26, 26, 1, 'Progresiones aritméticas'),
(27, 27, 1, 'Progresiones geométricas'),
(28, 28, 1, 'Transformaciones geométricas'),
(29, 29, 1, 'Simetría y reflexión'),
(30, 30, 1, 'Triángulos y sus propiedades'),
(31, 31, 1, 'Cuadriláteros'),
(32, 32, 1, 'Círculos y circunferencia'),
(33, 33, 1, 'Introducción a trigonometría'),
(34, 34, 1, 'Funciones trigonométricas básicas'),
(35, 35, 1, 'Aplicaciones de trigonometría'),
(36, 36, 1, 'Estadística descriptiva'),
(37, 37, 1, 'Probabilidad avanzada'),
(38, 38, 1, 'Resolución de problemas complejos'),
(39, 39, 1, 'Matemáticas aplicadas a la vida diaria'),
(40, 40, 1, 'Repaso y preparación para exámenes');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tokensesion`
--

CREATE TABLE `tokensesion` (
  `id_usuario` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `fecha_creacion` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tokensesion`
--

INSERT INTO `tokensesion` (`id_usuario`, `token`, `fecha_creacion`) VALUES
(4, '15fc118b-e7da-11ef-b979-282801a11dbf', '2025-02-10 16:47:40');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id_usuario` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  `apellido_paterno` varchar(255) NOT NULL,
  `apellido_materno` varchar(255) NOT NULL,
  `sexo` enum('Masculino','Femenino') NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `url_imagen` varchar(255) NOT NULL DEFAULT 'https://108.181.169.248/IMG-FOCUSCLASS/perfil_default.png',
  `telefono` varchar(20) NOT NULL,
  `ubigeo` varchar(6) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `fecha_nacimiento` date NOT NULL,
  `tipo_doc` enum('DNI','Carne de extranjería','Pasaporte') NOT NULL,
  `num_documento` varchar(15) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'active',
  `codigo_recuperacion` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id_usuario`, `nombre`, `apellido_paterno`, `apellido_materno`, `sexo`, `email`, `password`, `url_imagen`, `telefono`, `ubigeo`, `direccion`, `fecha_nacimiento`, `tipo_doc`, `num_documento`, `estado`, `codigo_recuperacion`) VALUES
(1, 'Juan Jose', 'Pérez', 'Mendosa', 'Masculino', 'kevind@reseller.hostea.pe', 'newpassword', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=12345678_Juan_Jose_P__rez', '555-5678', '010101', 'Calle Falsa 456', '1980-04-23', 'DNI', '12345678', 'active', '235656'),
(2, 'María', 'Lopez', 'Lopez', 'Masculino', 'maria.lopez@instituto.com', 'password123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '555-2345', '020202', 'Avenida Siempreviva 789', '1975-05-12', 'DNI', '87654321', 'active', NULL),
(3, 'Carlos', 'Gomez', 'Gomez', 'Masculino', 'carlos.gomez@instituto.com', 'password123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '555-6789', '030303', 'Calle Principal 111', '1985-06-15', 'DNI', '11223344', 'active', NULL),
(4, 'Kevin', 'Duran', 'Llamacuri', 'Masculino', '71806587@continental.edu.pe', '12345678', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71806587_Kevin_Duran', '998973240', '120903', 'Calle Central 999', '2000-05-09', 'DNI', '71806587', 'active', NULL),
(49, 'Cristian Daniel ', 'Blaz', 'Alvarado', 'Masculino', 'danielblaz59@gmail.com', 'Mydfast_123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '952547645', '120114', 'Jr. 28 de Julio #1370 CHILCA,HUANCAYO ; casa de 3 pisos puerta negra con portón negro.', '2000-10-18', 'DNI', '71500070', 'active', NULL),
(50, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo@ejemplo.mx', '123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '952547645', '120210', 'C. Falsa 445', '2000-10-18', 'DNI', '71500071', 'active', NULL),
(51, 'João', 'Souza', 'Silva', 'Masculino', 'teste@exemplo.us', '123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '952547645', '120114', 'Rua Inexistente, 2000', '2000-10-18', 'DNI', '72724516', 'active', NULL),
(52, 'Ana', 'Martinez', 'Lopez', 'Femenino', 'ana.martinez@example.com', '1243343', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '123456789', '200202', 'Calle Ficticia 456', '1995-05-05', 'Pasaporte', '1243343', 'active', NULL),
(53, 'Carlos', 'Fernandez', 'Sanchez', 'Femenino', 'carlos.fernandez@example.com', '98765432', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '987654321', '150202', 'Avenida Libertador 456', '1992-07-22', 'DNI', '98765432', 'active', NULL),
(54, 'Ana', 'Gonzalez', 'Lopez', 'Femenino', 'ana.gonzalez@example.com', '43206788', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '912345678', '150203', 'Calle Ficticia 123', '1988-05-15', 'DNI', '43206788', 'active', NULL),
(55, 'Luis', 'Martinez', 'Rodriguez', 'Masculino', 'luis.martinez@example.com', '23456789', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '933456789', '150204', 'Avenida Central 789', '1995-11-10', 'DNI', '23456789', 'active', NULL),
(56, 'Mariana', 'Perez', 'Garcia', 'Femenino', 'mariana.perez@example.com', '34567890', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '944567890', '150205', 'Calle del Sol 321', '1993-03-05', 'DNI', '34567890', 'active', NULL),
(57, 'Jose', 'Lopez', 'Martinez', 'Masculino', 'jose.lopez@example.com', '45678901', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '955678901', '150206', 'Avenida San Martin 654', '1990-02-14', 'DNI', '45678901', 'active', NULL),
(58, 'Isabel', 'Ramirez', 'Alvarez', 'Femenino', 'isabel.ramirez@example.com', '56789012', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '977890123', '150207', 'Calle de la Paz 987', '1994-08-30', 'DNI', '56789012', 'active', NULL),
(59, 'Pedro', 'Gomez', 'Diaz', 'Masculino', 'pedro.gomez@example.com', '67890123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '966789012', '150208', 'Calle 8 de Octubre 112', '1991-12-01', 'DNI', '67890123', 'active', NULL),
(60, 'Sofia', 'Serrano', 'Lopez', 'Femenino', 'sofia.serrano@example.com', '78901234', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '922345678', '150209', 'Calle Bellavista 135', '1996-09-22', 'DNI', '78901234', 'active', NULL),
(61, 'Diego', 'Hernandez', 'Morales', 'Masculino', 'diego.hernandez@example.com', '89012345', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=perfil_default', '966234567', '150210', 'Avenida Los Heroes 541', '1989-06-18', 'DNI', '89012345', 'active', NULL),
(62, 'Kent', 'Maccall', 'Argent', 'Masculino', 'Kent.Argent@example.com', '68542685', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=68542685_Kent_Maccall', '914245368', '150202', 'Avenida Libertador 666', '1992-07-22', 'DNI', '68542685', 'active', NULL),
(63, 'Toby', 'Still', 'Mencos', 'Masculino', 'Toby.Still@perez.com', '999999999', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=64554587_Toby_Still', '988752121', '150101', 'Av. Principal 123, Lima, Perú', '2000-05-15', 'DNI', '64554587', 'active', NULL),
(64, 'Delvis', 'Ortiz', 'Mendoza', 'Masculino', 'Delvis.Ortiz@exm.com', '999999999', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=19564872_Delvis_Ortiz', '964381223', '150101', 'Av. Principal 123, Lima, Perú', '2000-05-15', 'DNI', '19564872', 'active', NULL),
(65, 'Carlos', 'Fernandez', 'Sanchez', 'Masculino', 'carlos.fernandez123@example.com', '91843923', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=91843923_Carlos_Fernandez', '987654321', '150202', 'Avenida Libertador 456', '1992-07-22', 'DNI', '91843923', 'active', NULL),
(66, 'Mariano', 'Ponte', 'De Leon', 'Masculino', 'Mariano.Ponte@exm.com', '12345678', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=25252525_Mariano_Ponte', '952565412', '150101', 'Av. Principal 123, Lima, Perú', '2000-05-15', 'DNI', '25252525', 'active', NULL),
(67, 'Marbin', 'Tapia', 'Vidal', 'Masculino', 'Marbin.Tapia@example.com', '12121212', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=12121212_Marbin_Tapia', '987654321', '150202', 'Avenida Libertador 456', '1992-07-22', 'DNI', '12121212', 'active', NULL),
(68, 'Pedro', 'Mendez', 'Huyali', 'Masculino', 'Pedro.Mendez@exm.com', '12345678', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=36363636_Pedro_Mendez', '926541254', '150101', 'Av. Principal 123, Lima, Perú', '2000-05-15', 'DNI', '36363636', 'active', NULL),
(70, 'Jeferson', 'Maldini', 'Orestes', 'Masculino', 'Jeferson.Maldini@example.com', '45454545', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=45454545_Jeferson_Maldini', '987654321', '150202', 'Avenida Libertador 456', '1992-07-22', 'DNI', '45454545', 'active', NULL),
(71, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo1515@ejemplo.mx', '71715050', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71715050_Juan_Francisco_Garc__a', '952547645', '120107', 'C. Falsa 445', '2000-10-18', 'DNI', '71715050', 'active', NULL),
(72, 'João', 'Souza', 'Silva', 'Masculino', 'teste123@exemplo.us', '71715051', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71715051_Jo__o_Souza', '952547645', '120501', 'Rua Inexistente, 2000', '2000-10-18', 'DNI', '71715051', 'active', NULL),
(73, 'Jon', 'Blaz', 'Alva', 'Masculino', 'test12345@example.us', '71715252', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71715252_Jon_Blaz', '952547645', '120606', '1600 Fake Street', '2000-10-18', 'DNI', '71715252', 'active', NULL),
(74, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo123@ejemplo.mx', '71500089', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71500089_Juan_Francisco_Garc__a', '952547645', '080705', 'C. Falsa 445', '2000-10-18', 'DNI', '71500089', 'active', NULL),
(75, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo1234@ejemplo.mx', '71715174', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71715174_Juan_Francisco_Garc__a', '952547645', '090408', 'C. Falsa 445', '2000-10-18', 'DNI', '71715174', 'active', NULL),
(76, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo12134@ejemplo.mx', '71715176', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71715176_Juan_Francisco_Garc__a', '952547645', '090408', 'C. Falsa 445', '2000-10-18', 'DNI', '71715176', 'active', NULL),
(77, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo50501@ejemplo.mx', '71715074', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71715074_Juan_Francisco_Garc__a', '952547645', '100606', 'C. Falsa 445', '2000-10-18', 'DNI', '71715074', 'active', NULL),
(78, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo5252@ejemplo.mx', 'Mydfast_123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=72724545_Juan_Francisco_Garc__a', '952547645', '100703', 'C. Falsa 445', '2000-10-18', 'DNI', '72724545', 'active', NULL),
(79, 'Juan Francisco', 'García', 'Flores', 'Masculino', 'ejemplo1212@ejemplo.mx', '71717474', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71717474_Juan_Francisco_Garc__a', '952547645', '120114', 'C. Falsa 445', '2000-10-18', 'DNI', '71717474', 'active', NULL),
(80, 'Cristian Daniel', 'Blaz ', 'Alvarado', 'Masculino', 'danielblaz131516@gmail.com', 'Mydfast_123', 'https://ll6aenqwm9.execute-api.us-east-1.amazonaws.com/service/util-01-imagen?img=71850050_Cristian_Daniel_Blaz_', '952547645', '120114', 'Jr. 28 de Julio #1370 CHILCA,HUANCAYO ; casa de 3 pisos puerta negra con portón negro.', '2000-10-18', 'DNI', '71850050', 'active', NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `alumno`
--
ALTER TABLE `alumno`
  ADD PRIMARY KEY (`id_alumno`),
  ADD UNIQUE KEY `codigo_alumno` (`codigo_alumno`),
  ADD KEY `fk_alumno_usuario` (`id_usuario`),
  ADD KEY `fk_alumno_institucion` (`id_institucion`);

--
-- Indices de la tabla `alumno_apoderado`
--
ALTER TABLE `alumno_apoderado`
  ADD PRIMARY KEY (`id_alumno_apoderado`),
  ADD KEY `fk_alumno_apoderado_alumno` (`id_alumno`),
  ADD KEY `fk_alumno_apoderado_apoderado` (`id_apoderado`),
  ADD KEY `fk_alumno_apoderado_institucion` (`id_institucion`);

--
-- Indices de la tabla `alumno_matricula`
--
ALTER TABLE `alumno_matricula`
  ADD PRIMARY KEY (`id_alumno_matricula`),
  ADD KEY `fk_alumno_matricula_alumno` (`id_alumno`),
  ADD KEY `fk_alumno_matricula_matricula` (`id_matricula`),
  ADD KEY `fk_alumno_matricula_seccion` (`id_seccion`);

--
-- Indices de la tabla `alumno_matricula_curso`
--
ALTER TABLE `alumno_matricula_curso`
  ADD PRIMARY KEY (`id_alumno_matricula_curso`),
  ADD KEY `fk_alumno` (`id_alumno_matricula`),
  ADD KEY `fk_curso` (`id_curso`);

--
-- Indices de la tabla `apoderado`
--
ALTER TABLE `apoderado`
  ADD PRIMARY KEY (`id_apoderado`),
  ADD UNIQUE KEY `codigo_apoderado` (`codigo_apoderado`),
  ADD KEY `fk_apoderado_usuario` (`id_usuario`),
  ADD KEY `fk_apoderado_institucion` (`id_institucion`);

--
-- Indices de la tabla `asistencia`
--
ALTER TABLE `asistencia`
  ADD PRIMARY KEY (`id_asistencia`),
  ADD KEY `id_alumno_matricula_curso` (`id_alumno_matricula_curso`);

--
-- Indices de la tabla `aviso`
--
ALTER TABLE `aviso`
  ADD PRIMARY KEY (`id_aviso`),
  ADD KEY `fk_avisos_alumno` (`id_alumno`);

--
-- Indices de la tabla `constantes`
--
ALTER TABLE `constantes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `coordinador`
--
ALTER TABLE `coordinador`
  ADD PRIMARY KEY (`id_coordinador`),
  ADD UNIQUE KEY `codigo_coordinador` (`codigo_coordinador`),
  ADD KEY `fk_coordinador_usuario` (`id_usuario`),
  ADD KEY `fk_coordinador_institucion` (`id_institucion`);

--
-- Indices de la tabla `curso`
--
ALTER TABLE `curso`
  ADD PRIMARY KEY (`id_curso`),
  ADD KEY `fk_curso_grado` (`id_grado`);

--
-- Indices de la tabla `curso_docente`
--
ALTER TABLE `curso_docente`
  ADD PRIMARY KEY (`id_curso_docente`),
  ADD KEY `fk_curso_docente_curso` (`id_curso`),
  ADD KEY `fk_curso_docente_docente` (`id_docente`);

--
-- Indices de la tabla `curso_docente_horario`
--
ALTER TABLE `curso_docente_horario`
  ADD PRIMARY KEY (`id_horario`),
  ADD KEY `id_curso_docente` (`id_curso_docente`);

--
-- Indices de la tabla `docente`
--
ALTER TABLE `docente`
  ADD PRIMARY KEY (`id_docente`),
  ADD UNIQUE KEY `codigo_docente` (`codigo_docente`),
  ADD KEY `id_institucion` (`id_institucion`),
  ADD KEY `fk_docente_usuario` (`id_usuario`);

--
-- Indices de la tabla `etapa_escolar`
--
ALTER TABLE `etapa_escolar`
  ADD PRIMARY KEY (`id_etapa`),
  ADD KEY `fk_etapa_matricula` (`id_matricula`);

--
-- Indices de la tabla `etapa_planificacion`
--
ALTER TABLE `etapa_planificacion`
  ADD PRIMARY KEY (`id_etapa_planificacion`),
  ADD KEY `fk_etapa_planificacion_etapa` (`id_etapa`);

--
-- Indices de la tabla `grado`
--
ALTER TABLE `grado`
  ADD PRIMARY KEY (`id_grado`),
  ADD KEY `fk_grado_nivel` (`id_nivel`);

--
-- Indices de la tabla `institucion`
--
ALTER TABLE `institucion`
  ADD PRIMARY KEY (`id_institucion`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indices de la tabla `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `matricula`
--
ALTER TABLE `matricula`
  ADD PRIMARY KEY (`id_matricula`),
  ADD UNIQUE KEY `anio_academico` (`anio_academico`),
  ADD KEY `id_institucion` (`id_institucion`);

--
-- Indices de la tabla `nivel`
--
ALTER TABLE `nivel`
  ADD PRIMARY KEY (`id_nivel`),
  ADD KEY `fk_nivel_institucion` (`id_institucion`);

--
-- Indices de la tabla `nota`
--
ALTER TABLE `nota`
  ADD PRIMARY KEY (`id_nota`),
  ADD KEY `fk_nota_etapa_escolar` (`id_etapa_escolar`);

--
-- Indices de la tabla `nota_alumno_curso`
--
ALTER TABLE `nota_alumno_curso`
  ADD PRIMARY KEY (`id_nota_alumno_curso`),
  ADD KEY `fk_nota_alumno_curso_nota` (`id_nota`),
  ADD KEY `fk_nota_alumno_matricula_curso` (`id_alumno_matricula_curso`);

--
-- Indices de la tabla `seccion`
--
ALTER TABLE `seccion`
  ADD PRIMARY KEY (`id_seccion`),
  ADD KEY `fk_seccion_grado` (`id_grado`);

--
-- Indices de la tabla `tema`
--
ALTER TABLE `tema`
  ADD PRIMARY KEY (`id_tema`),
  ADD KEY `fk_tema_etapa_planificacion` (`id_etapa_planificacion`),
  ADD KEY `fk_tema_curso` (`id_curso`);

--
-- Indices de la tabla `tokensesion`
--
ALTER TABLE `tokensesion`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `token` (`token`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `dni` (`num_documento`),
  ADD UNIQUE KEY `codigo_recuperacion` (`codigo_recuperacion`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `alumno`
--
ALTER TABLE `alumno`
  MODIFY `id_alumno` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT de la tabla `alumno_apoderado`
--
ALTER TABLE `alumno_apoderado`
  MODIFY `id_alumno_apoderado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `alumno_matricula`
--
ALTER TABLE `alumno_matricula`
  MODIFY `id_alumno_matricula` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT de la tabla `alumno_matricula_curso`
--
ALTER TABLE `alumno_matricula_curso`
  MODIFY `id_alumno_matricula_curso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=134;

--
-- AUTO_INCREMENT de la tabla `apoderado`
--
ALTER TABLE `apoderado`
  MODIFY `id_apoderado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `asistencia`
--
ALTER TABLE `asistencia`
  MODIFY `id_asistencia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=675;

--
-- AUTO_INCREMENT de la tabla `aviso`
--
ALTER TABLE `aviso`
  MODIFY `id_aviso` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `constantes`
--
ALTER TABLE `constantes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `coordinador`
--
ALTER TABLE `coordinador`
  MODIFY `id_coordinador` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `curso`
--
ALTER TABLE `curso`
  MODIFY `id_curso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `curso_docente`
--
ALTER TABLE `curso_docente`
  MODIFY `id_curso_docente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `curso_docente_horario`
--
ALTER TABLE `curso_docente_horario`
  MODIFY `id_horario` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `docente`
--
ALTER TABLE `docente`
  MODIFY `id_docente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `etapa_escolar`
--
ALTER TABLE `etapa_escolar`
  MODIFY `id_etapa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `etapa_planificacion`
--
ALTER TABLE `etapa_planificacion`
  MODIFY `id_etapa_planificacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT de la tabla `grado`
--
ALTER TABLE `grado`
  MODIFY `id_grado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `institucion`
--
ALTER TABLE `institucion`
  MODIFY `id_institucion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `logs`
--
ALTER TABLE `logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT de la tabla `matricula`
--
ALTER TABLE `matricula`
  MODIFY `id_matricula` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `nivel`
--
ALTER TABLE `nivel`
  MODIFY `id_nivel` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `nota`
--
ALTER TABLE `nota`
  MODIFY `id_nota` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `nota_alumno_curso`
--
ALTER TABLE `nota_alumno_curso`
  MODIFY `id_nota_alumno_curso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1123;

--
-- AUTO_INCREMENT de la tabla `seccion`
--
ALTER TABLE `seccion`
  MODIFY `id_seccion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `tema`
--
ALTER TABLE `tema`
  MODIFY `id_tema` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `alumno`
--
ALTER TABLE `alumno`
  ADD CONSTRAINT `fk_alumno_institucion` FOREIGN KEY (`id_institucion`) REFERENCES `institucion` (`id_institucion`),
  ADD CONSTRAINT `fk_alumno_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `alumno_apoderado`
--
ALTER TABLE `alumno_apoderado`
  ADD CONSTRAINT `fk_alumno_apoderado_alumno` FOREIGN KEY (`id_alumno`) REFERENCES `alumno` (`id_alumno`),
  ADD CONSTRAINT `fk_alumno_apoderado_apoderado` FOREIGN KEY (`id_apoderado`) REFERENCES `apoderado` (`id_apoderado`),
  ADD CONSTRAINT `fk_alumno_apoderado_institucion` FOREIGN KEY (`id_institucion`) REFERENCES `institucion` (`id_institucion`);

--
-- Filtros para la tabla `alumno_matricula`
--
ALTER TABLE `alumno_matricula`
  ADD CONSTRAINT `fk_alumno_matricula_alumno` FOREIGN KEY (`id_alumno`) REFERENCES `alumno` (`id_alumno`),
  ADD CONSTRAINT `fk_alumno_matricula_matricula` FOREIGN KEY (`id_matricula`) REFERENCES `matricula` (`id_matricula`),
  ADD CONSTRAINT `fk_alumno_matricula_seccion` FOREIGN KEY (`id_seccion`) REFERENCES `seccion` (`id_seccion`);

--
-- Filtros para la tabla `alumno_matricula_curso`
--
ALTER TABLE `alumno_matricula_curso`
  ADD CONSTRAINT `fk_alumno` FOREIGN KEY (`id_alumno_matricula`) REFERENCES `alumno_matricula` (`id_alumno_matricula`),
  ADD CONSTRAINT `fk_curso` FOREIGN KEY (`id_curso`) REFERENCES `curso` (`id_curso`);

--
-- Filtros para la tabla `apoderado`
--
ALTER TABLE `apoderado`
  ADD CONSTRAINT `fk_apoderado_institucion` FOREIGN KEY (`id_institucion`) REFERENCES `institucion` (`id_institucion`),
  ADD CONSTRAINT `fk_apoderado_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `asistencia`
--
ALTER TABLE `asistencia`
  ADD CONSTRAINT `asistencia_ibfk_1` FOREIGN KEY (`id_alumno_matricula_curso`) REFERENCES `alumno_matricula_curso` (`id_alumno_matricula_curso`);

--
-- Filtros para la tabla `aviso`
--
ALTER TABLE `aviso`
  ADD CONSTRAINT `fk_avisos_alumno` FOREIGN KEY (`id_alumno`) REFERENCES `alumno` (`id_alumno`) ON DELETE CASCADE;

--
-- Filtros para la tabla `coordinador`
--
ALTER TABLE `coordinador`
  ADD CONSTRAINT `fk_coordinador_institucion` FOREIGN KEY (`id_institucion`) REFERENCES `institucion` (`id_institucion`),
  ADD CONSTRAINT `fk_coordinador_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `curso`
--
ALTER TABLE `curso`
  ADD CONSTRAINT `fk_curso_grado` FOREIGN KEY (`id_grado`) REFERENCES `grado` (`id_grado`) ON DELETE CASCADE;

--
-- Filtros para la tabla `curso_docente`
--
ALTER TABLE `curso_docente`
  ADD CONSTRAINT `fk_curso_docente_curso` FOREIGN KEY (`id_curso`) REFERENCES `curso` (`id_curso`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_curso_docente_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`) ON DELETE CASCADE;

--
-- Filtros para la tabla `curso_docente_horario`
--
ALTER TABLE `curso_docente_horario`
  ADD CONSTRAINT `curso_docente_horario_ibfk_1` FOREIGN KEY (`id_curso_docente`) REFERENCES `curso_docente` (`id_curso_docente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `docente`
--
ALTER TABLE `docente`
  ADD CONSTRAINT `docente_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  ADD CONSTRAINT `docente_ibfk_2` FOREIGN KEY (`id_institucion`) REFERENCES `institucion` (`id_institucion`),
  ADD CONSTRAINT `fk_docente_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

--
-- Filtros para la tabla `etapa_escolar`
--
ALTER TABLE `etapa_escolar`
  ADD CONSTRAINT `fk_etapa_matricula` FOREIGN KEY (`id_matricula`) REFERENCES `matricula` (`id_matricula`);

--
-- Filtros para la tabla `etapa_planificacion`
--
ALTER TABLE `etapa_planificacion`
  ADD CONSTRAINT `fk_etapa_planificacion_etapa` FOREIGN KEY (`id_etapa`) REFERENCES `etapa_escolar` (`id_etapa`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `grado`
--
ALTER TABLE `grado`
  ADD CONSTRAINT `fk_grado_nivel` FOREIGN KEY (`id_nivel`) REFERENCES `nivel` (`id_nivel`);

--
-- Filtros para la tabla `matricula`
--
ALTER TABLE `matricula`
  ADD CONSTRAINT `matricula_ibfk_1` FOREIGN KEY (`id_institucion`) REFERENCES `institucion` (`id_institucion`);

--
-- Filtros para la tabla `nivel`
--
ALTER TABLE `nivel`
  ADD CONSTRAINT `fk_nivel_institucion` FOREIGN KEY (`id_institucion`) REFERENCES `institucion` (`id_institucion`);

--
-- Filtros para la tabla `nota`
--
ALTER TABLE `nota`
  ADD CONSTRAINT `fk_nota_etapa_escolar` FOREIGN KEY (`id_etapa_escolar`) REFERENCES `etapa_escolar` (`id_etapa`);

--
-- Filtros para la tabla `nota_alumno_curso`
--
ALTER TABLE `nota_alumno_curso`
  ADD CONSTRAINT `fk_nota_alumno_curso_nota` FOREIGN KEY (`id_nota`) REFERENCES `nota` (`id_nota`),
  ADD CONSTRAINT `fk_nota_alumno_matricula_curso` FOREIGN KEY (`id_alumno_matricula_curso`) REFERENCES `alumno_matricula_curso` (`id_alumno_matricula_curso`);

--
-- Filtros para la tabla `seccion`
--
ALTER TABLE `seccion`
  ADD CONSTRAINT `fk_seccion_grado` FOREIGN KEY (`id_grado`) REFERENCES `grado` (`id_grado`);

--
-- Filtros para la tabla `tema`
--
ALTER TABLE `tema`
  ADD CONSTRAINT `fk_tema_curso` FOREIGN KEY (`id_curso`) REFERENCES `curso` (`id_curso`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tema_etapa_planificacion` FOREIGN KEY (`id_etapa_planificacion`) REFERENCES `etapa_planificacion` (`id_etapa_planificacion`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `tokensesion`
--
ALTER TABLE `tokensesion`
  ADD CONSTRAINT `tokensesion_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`);

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `limpiar_tokens_expirados` ON SCHEDULE EVERY 1 MINUTE STARTS '2024-11-26 21:08:39' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DECLARE tiempo_lifetime INT;

    SELECT CAST(valor AS UNSIGNED) INTO tiempo_lifetime
    FROM Constantes
    WHERE nombre = 'TOKEN_LIFETIME'
    LIMIT 1;


    DELETE FROM TokenSesion
    WHERE TIMESTAMPDIFF(MINUTE, fecha_creacion, NOW()) > tiempo_lifetime;
END$$

CREATE DEFINER=`root`@`localhost` EVENT `asignar_cursos` ON SCHEDULE EVERY 1 MINUTE STARTS '2025-01-22 17:23:34' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
  INSERT INTO alumno_matricula_curso (id_alumno_matricula, id_curso, fecha_inscripcion)
  SELECT 
    am.id_alumno_matricula,
    c.id_curso,
    CURDATE()
  FROM 
    alumno_matricula am
  INNER JOIN seccion s ON am.id_seccion = s.id_seccion
  INNER JOIN grado g ON s.id_grado = g.id_grado
  INNER JOIN curso c ON c.id_grado = g.id_grado
  WHERE 
    NOT EXISTS (
      SELECT 1 
      FROM alumno_matricula_curso amc 
      WHERE amc.id_alumno_matricula = am.id_alumno_matricula 
      AND amc.id_curso = c.id_curso
    );
END$$

CREATE DEFINER=`root`@`localhost` EVENT `asignar_notas` ON SCHEDULE EVERY 1 MINUTE STARTS '2025-01-22 17:40:21' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
  INSERT INTO nota_alumno_curso (id_alumno_matricula_curso, id_nota, nota_obtenida, fecha)
  SELECT 
    amc.id_alumno_matricula_curso, 
    n.id_nota,
    0.00, -- Nota inicial por defecto
    CURDATE()
  FROM 
    alumno_matricula_curso amc
  INNER JOIN alumno_matricula am ON amc.id_alumno_matricula = am.id_alumno_matricula
  INNER JOIN seccion s ON am.id_seccion = s.id_seccion
  INNER JOIN grado g ON s.id_grado = g.id_grado
  INNER JOIN curso c ON amc.id_curso = c.id_curso AND c.id_grado = g.id_grado
  INNER JOIN matricula m ON am.id_alumno_matricula = am.id_alumno_matricula
  INNER JOIN etapa_escolar ee ON ee.id_matricula = m.id_matricula
  INNER JOIN nota n ON ee.id_etapa = n.id_etapa_escolar
  WHERE 
    NOT EXISTS (
      SELECT 1 
      FROM nota_alumno_curso nac 
      WHERE nac.id_alumno_matricula_curso = amc.id_alumno_matricula_curso 
      AND nac.id_nota = n.id_nota
    );
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
