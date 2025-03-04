-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 21-01-2025 a las 00:14:47
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
(17, 65, 1, '00001-S-91843923', 'Inactivo'),
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
(1, 3, 1, 1, 'Padre');

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
(6, 1, 1, '2025-01-05'),
(7, 2, 1, '2025-01-05'),
(8, 3, 1, '2025-01-05'),
(9, 4, 1, '2025-01-05'),
(10, 5, 1, '2025-01-05'),
(11, 6, 1, '2025-01-05'),
(12, 7, 1, '2025-01-05'),
(13, 8, 1, '2025-01-05'),
(14, 9, 1, '2025-01-05'),
(15, 10, 1, '2025-01-05'),
(16, 11, 1, '2025-01-05'),
(17, 12, 1, '2025-01-05'),
(18, 13, 1, '2025-01-05'),
(19, 1, 2, '2025-01-05'),
(20, 2, 2, '2025-01-05'),
(21, 3, 2, '2025-01-05'),
(22, 4, 2, '2025-01-05'),
(23, 5, 2, '2025-01-05'),
(24, 6, 2, '2025-01-05'),
(25, 7, 2, '2025-01-05'),
(26, 8, 2, '2025-01-05'),
(27, 9, 2, '2025-01-05'),
(28, 10, 2, '2025-01-05'),
(29, 11, 2, '2025-01-05'),
(30, 12, 2, '2025-01-05'),
(31, 13, 2, '2025-01-05'),
(37, 1, 3, '2025-01-05'),
(38, 2, 3, '2025-01-05'),
(39, 3, 3, '2025-01-05'),
(40, 4, 3, '2025-01-05'),
(41, 5, 3, '2025-01-05'),
(42, 6, 3, '2025-01-05'),
(43, 7, 3, '2025-01-05'),
(44, 8, 3, '2025-01-05'),
(45, 9, 3, '2025-01-05'),
(46, 10, 3, '2025-01-05'),
(47, 11, 3, '2025-01-05'),
(48, 12, 3, '2025-01-05'),
(49, 13, 3, '2025-01-05'),
(52, 14, 1, '2025-01-05'),
(53, 14, 2, '2025-01-05'),
(54, 14, 3, '2025-01-05'),
(55, 15, 1, '2025-01-05'),
(56, 15, 2, '2025-01-05'),
(57, 15, 3, '2025-01-05'),
(58, 16, 1, '2025-01-08'),
(59, 16, 2, '2025-01-08'),
(60, 16, 3, '2025-01-08'),
(61, 17, 1, '2025-01-08'),
(62, 17, 2, '2025-01-08'),
(63, 17, 3, '2025-01-08'),
(64, 18, 1, '2025-01-08'),
(65, 18, 2, '2025-01-08'),
(66, 18, 3, '2025-01-08'),
(67, 19, 1, '2025-01-08'),
(68, 19, 2, '2025-01-08'),
(69, 19, 3, '2025-01-08'),
(70, 20, 1, '2025-01-08'),
(71, 20, 2, '2025-01-08'),
(72, 20, 3, '2025-01-08'),
(73, 21, 1, '2025-01-08'),
(74, 21, 2, '2025-01-08'),
(75, 21, 3, '2025-01-08'),
(76, 24, 1, '2025-01-08'),
(77, 24, 2, '2025-01-08'),
(78, 24, 3, '2025-01-08'),
(79, 25, 1, '2025-01-08'),
(80, 25, 2, '2025-01-08'),
(81, 25, 3, '2025-01-08');

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
  `id_alumno_matricula` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `estado` enum('PRESENTE','AUSENTE','TARDANZA','JUSTIFICADO') NOT NULL DEFAULT 'AUSENTE',
  `observaciones` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(3, 1, 'Ciencias Sociales', 'Curso donde se ve toda la ciencia de la humanidad.', 'Activo');

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
(9, 3, 1);

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
  ADD UNIQUE KEY `uk_asistencia_unica` (`id_alumno_matricula`,`fecha`) USING BTREE,
  ADD KEY `fk_asistencia_alumno` (`id_alumno_matricula`);

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
  MODIFY `id_alumno_apoderado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `alumno_matricula`
--
ALTER TABLE `alumno_matricula`
  MODIFY `id_alumno_matricula` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT de la tabla `alumno_matricula_curso`
--
ALTER TABLE `alumno_matricula_curso`
  MODIFY `id_alumno_matricula_curso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=82;

--
-- AUTO_INCREMENT de la tabla `apoderado`
--
ALTER TABLE `apoderado`
  MODIFY `id_apoderado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `asistencia`
--
ALTER TABLE `asistencia`
  MODIFY `id_asistencia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

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
  MODIFY `id_curso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `curso_docente`
--
ALTER TABLE `curso_docente`
  MODIFY `id_curso_docente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

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
  MODIFY `id_nota_alumno_curso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  ADD CONSTRAINT `fk_asistencia_alumno` FOREIGN KEY (`id_alumno_matricula`) REFERENCES `alumno_matricula` (`id_alumno_matricula`);

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

CREATE DEFINER=`root`@`localhost` EVENT `asignar_cursos_automaticamente` ON SCHEDULE EVERY 1 MINUTE STARTS '2025-01-01 17:42:39' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    -- Insertar cursos para los alumnos que no tienen registros en alumno_matricula_curso
    INSERT INTO alumno_matricula_curso (id_alumno_matricula, id_curso, fecha_inscripcion)
    SELECT 
        am.id_alumno_matricula,
        c.id_curso,
        CURDATE() AS fecha_inscripcion
    FROM 
        alumno_matricula am
    JOIN 
        seccion s ON am.id_seccion = s.id_seccion
    JOIN 
        grado g ON s.id_grado = g.id_grado
    JOIN 
        curso c ON g.id_grado = c.id_grado
    LEFT JOIN 
        alumno_matricula_curso amc ON am.id_alumno_matricula = amc.id_alumno_matricula 
        AND c.id_curso = amc.id_curso
    WHERE 
        amc.id_alumno_matricula IS NULL; -- Solo insertar si no existe ya el registro
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
