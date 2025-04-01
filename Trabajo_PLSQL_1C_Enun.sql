DROP TABLE detalle_pedido CASCADE CONSTRAINTS;
DROP TABLE pedidos CASCADE CONSTRAINTS;
DROP TABLE platos CASCADE CONSTRAINTS;
DROP TABLE personal_servicio CASCADE CONSTRAINTS;
DROP TABLE clientes CASCADE CONSTRAINTS;

DROP SEQUENCE seq_pedidos;


-- Creación de tablas y secuencias



create sequence seq_pedidos;

CREATE TABLE clientes (
    id_cliente INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(20)
);

CREATE TABLE personal_servicio (
    id_personal INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    apellido VARCHAR2(100) NOT NULL,
    pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)
);

CREATE TABLE platos (
    id_plato INTEGER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    disponible INTEGER DEFAULT 1 CHECK (DISPONIBLE in (0,1))
);

CREATE TABLE pedidos (
    id_pedido INTEGER PRIMARY KEY,
    id_cliente INTEGER REFERENCES clientes(id_cliente),
    id_personal INTEGER REFERENCES personal_servicio(id_personal),
    fecha_pedido DATE DEFAULT SYSDATE,
    total DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE detalle_pedido (
    id_pedido INTEGER REFERENCES pedidos(id_pedido),
    id_plato INTEGER REFERENCES platos(id_plato),
    cantidad INTEGER NOT NULL,
    PRIMARY KEY (id_pedido, id_plato)
);


	
-- Procedimiento a implementar para realizar la reserva
create or replace procedure registrar_pedido(
    arg_id_cliente      INTEGER, 
    arg_id_personal     INTEGER, 
    arg_id_primer_plato INTEGER DEFAULT NULL,
    arg_id_segundo_plato INTEGER DEFAULT NULL
) is 
 begin
  null; -- sustituye esta línea por tu código
end;
/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites apra cada una)
-- * P4.1 ¿Como garantizas en tu codigo que un miembro del persona de servicio no supere el lımite de pedidos activos?
--
-- * P4.2 ¿Cómo evitas que dos transacciones concurrentes asignen un pedido al mismo personal de servicio cuyos pedidos activos estan a punto de superar el límite?
-- 
-- * P4.3 Una vez hechas las comprobaciones en los pasos 1 y 2, 
-- ¿podrías asegurar que el pedido se puede realizar de manera correcta en el paso 4 y no se generan inconsistencias? ¿Por qué?Recuerda que trabajamos en entornos con conexiones .concurrentes.
--
-- * P4.4 Si modificásemos la tabla de personal servicio añadiendo CHECK (pedido activos ≤ 5), ¿Qué implicaciones tendr´ıa entu código? 
-- ¿Cómo afectaría en la gestión de excepciones? 
-- Describe en detalle las modificaciones que deberías hacer en tu código para mejorar tu solución ante esta situación (puedes añadir pseudocódigo).
--
-- * P4.5¿Qué tipo de estrategia de programación has utilizado? ¿Cómo puede verse en tu código?
-- 


create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
    
    reset_seq('seq_pedidos');
        
  
    delete from Detalle_pedido;
    delete from Pedidos;
    delete from Platos;
    delete from Personal_servicio;
    delete from Clientes;
    
    -- Insertar datos de prueba
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (1, 'Pepe', 'Perez', '123456789');
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (2, 'Ana', 'Garcia', '987654321');
    
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (1, 'Carlos', 'Lopez', 0);
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (2, 'Maria', 'Fernandez', 5);
    
    insert into Platos (id_plato, nombre, precio, disponible) values (1, 'Sopa', 10.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (2, 'Pasta', 12.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (3, 'Carne', 15.0, 0);

    commit;
end;
/

exec inicializa_test;

-- Completa lost test, incluyendo al menos los del enunciado y añadiendo los que consideres necesarios

CREATE OR REPLACE PROCEDURE test_registrar_pedido IS
    -- Excepciones personalizadas
    ex_pedido_vacio EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_pedido_vacio, -20002);

    ex_plato_no_existe EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_plato_no_existe, -20004);

    ex_plato_no_disponible EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_plato_no_disponible, -20001);

    ex_personal_sobrecargado EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_personal_sobrecargado, -20003);

    -- Variables para los identificadores de prueba
    v_id_cliente INTEGER;
    v_id_personal INTEGER;
    v_id_primer_plato INTEGER;
    v_id_segundo_plato INTEGER;
BEGIN
    -- Inicializar los datos de prueba
    inicializa_test;

    -- Caso 1: Pedido correcto, se realiza exitosamente
    BEGIN
        -- Asignar valores válidos a las variables
        v_id_cliente := 1;
        v_id_personal := 1;
        v_id_primer_plato := 1;
        v_id_segundo_plato := 2;

        -- Intentar registrar el pedido
        registrar_pedido(v_id_cliente, v_id_personal, v_id_primer_plato, v_id_segundo_plato);
        DBMS_OUTPUT.PUT_LINE('Caso 1: Pedido registrado correctamente.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caso 1: Error inesperado - ' || SQLERRM);
    END;

    -- Caso 2: Pedido vacío (sin platos), debe devolver el error -20002
    BEGIN
        registrar_pedido(v_id_cliente, v_id_personal, NULL, NULL);
        DBMS_OUTPUT.PUT_LINE('Caso 2: Error - Se esperaba una excepción por pedido vacío.');
    EXCEPTION
        WHEN ex_pedido_vacio THEN
            DBMS_OUTPUT.PUT_LINE('Caso 2: Excepción capturada correctamente: Pedido vacío.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caso 2: Error inesperado - ' || SQLERRM);
    END;

    -- Caso 3: Pedido con un plato que no existe, debe devolver el error -20004
    BEGIN
        registrar_pedido(v_id_cliente, v_id_personal, 999, NULL);
        DBMS_OUTPUT.PUT_LINE('Caso 3: Error - Se esperaba una excepción por plato inexistente.');
    EXCEPTION
        WHEN ex_plato_no_existe THEN
            DBMS_OUTPUT.PUT_LINE('Caso 3: Excepción capturada correctamente: Plato no existe.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caso 3: Error inesperado - ' || SQLERRM);
    END;

    -- Caso 4: Pedido con un plato no disponible, debe devolver el error -20001
    BEGIN
        -- Suponiendo que el plato con ID 3 no está disponible
        registrar_pedido(v_id_cliente



set serveroutput on;
exec test_registrar_pedido;
