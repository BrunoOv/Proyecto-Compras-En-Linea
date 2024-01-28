CREATE DATABASE "ComprasEnLinea"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
CREATE SCHEMA Usuario
CREATE SCHEMA Operaciones
CREATE SCHEMA Articulo
CREATE SCHEMA Datos

CREATE TABLE Usuario.Cliente(
	Id_Cliente BIGSERIAL NOT NULL,
	Nombre_Cliente VARCHAR(50) NOT NULL,
	Correo_Electronico VARCHAR(50) NOT NULL,
	CONSTRAINT PK_CLIENTE PRIMARY KEY (Id_Cliente) 
)


CREATE TABLE Usuario.Proveedor(
	Id_Proveedor BIGSERIAL NOT NULL,
	Correo_Electronico VARCHAR(50) NOT NULL,
	Nombre_Provedoor VARCHAR(50) NOT NULL,
	Domicilio_Fiscal VARCHAR(100) NOT NULL,

	CONSTRAINT PK_PROVEEDOR PRIMARY KEY (Id_Proveedor) 
)

CREATE TABLE Articulo.Producto(
	Id_Producto BIGSERIAL NOT NULL,
	Nombre_Producto VARCHAR(50) NOT NULL,
	Precio_Publico_Producto MONEY NOT NULL,
	Precio_Publico_Proveedor MONEY NOT NULL,
	Color VARCHAR(10) NOT NULL,
	Stock INT,

	CONSTRAINT PK_PRODUCTO PRIMARY KEY (Id_Producto) 
)

CREATE TABLE Datos.Telefono_Cliente(
	Id_Cliente BIGINT NOT NULL,
	Numero VARCHAR(15) NOT NULL,

	CONSTRAINT FK_CLIENTE FOREIGN KEY (Id_Cliente)
	REFERENCES Usuario.Cliente(Id_Cliente)
)

ALTER TABLE Datos.Telefono_Cliente ADD constraint UQ_TELEFONO_CLIENTE UNIQUE(Numero)

CREATE TABLE Datos.Telefono_Proveedor(
	Id_Proveedor BIGINT NOT NULL,
	Numero VARCHAR(15) NOT NULL,

	CONSTRAINT FK_PROVEEDOR FOREIGN KEY (Id_Proveedor)
	REFERENCES Usuario.Proveedor(Id_Proveedor)
)
ALTER TABLE Datos.Telefono_Proveedor ADD CONSTRAINT UQ_TELEFONO_PROVEEDOR UNIQUE(Numero)


CREATE TABLE Datos.Tarjeta_Cliente(
	Id_Tarjeta BIGSERIAL NOT NULL,
	Id_Cliente BIGINT NOT NULL,
	Numero_Tarjeta VARCHAR(16) NOT NULL,
	CVV VARCHAR(3) NOT NULL,
	Banco VARCHAR(20) NOT NULL,
	Fecha DATE NOT NULL,

	CONSTRAINT PK_TARJETA_CLIENTE PRIMARY KEY (Id_Tarjeta),
	CONSTRAINT FK_CLIENTE_TARJETA FOREIGN KEY (Id_Cliente)
	REFERENCES Usuario.Cliente(Id_Cliente)
)
ALTER TABLE Datos.Tarjeta_Cliente ADD constraint UQ_NUMERO_TARJETA UNIQUE(Numero_Tarjeta)


CREATE TABLE Operaciones.Orden(
	Num_Orden BIGSERIAL NOT NULL,
	Id_Proveedor BIGINT NOT NULL,
	Fecha_Orden DATE NOT NULL,
	Total MONEY NOT NULL,

	CONSTRAINT PK_ORDEN PRIMARY KEY (Num_Orden),
	CONSTRAINT FK_PROVEEDOR_ORDEN FOREIGN KEY (Id_Proveedor)
	REFERENCES Usuario.Proveedor(Id_Proveedor)
)

CREATE TABLE Operaciones.Detalle_Orden(
	Num_Orden BIGINT NOT NULL,
	Id_Producto BIGINT NOT NULL,
	Cantidad INT NOT NULL,
	SubTotal MONEY,

	
	CONSTRAINT FK_ORDEN_DETALLE_ORDEN FOREIGN KEY (Num_Orden)
	REFERENCES Operaciones.Orden(Num_Orden),
	CONSTRAINT FK_PRODUCTO_DETALLE_ORDEN FOREIGN KEY (Id_Producto)
	REFERENCES Articulo.Producto(Id_Producto)
)
CREATE TABLE Operaciones.Carrito_Venta(
	Id_Carrito BIGSERIAL NOT NULL,
	Id_Tarjeta_Cliente BIGINT NOT NULL,
	Forma_De_Pago VARCHAR(50) NOT NULL,
	Fecha_Venta DATE NOT NULL,
	Total_Carrito MONEY,

	CONSTRAINT PK_CARRITO PRIMARY KEY (Id_Carrito),
	CONSTRAINT FK_TARJETA_CLIENTE_CARRITO FOREIGN KEY (Id_Tarjeta_Cliente)
	REFERENCES Datos.Tarjeta_Cliente(Id_Tarjeta)
)

CREATE TABLE Operaciones.Detalle_Carrito(
	Id_Carrito BIGINT NOT NULL,
	Id_Producto BIGINT NOT NULL,
	Cantidad INT NOT NULL,
	SubTotal MONEY,

	
	CONSTRAINT FK_CARRITO_DETALLE_CARRITO FOREIGN KEY (Id_Carrito)
	REFERENCES Operaciones.Carrito_Venta(Id_Carrito),
	CONSTRAINT FK_PRODUCTO_DETALLE_Carrito FOREIGN KEY (Id_Producto)
	REFERENCES Articulo.Producto(Id_Producto)
)

CREATE TABLE Operaciones.Devolucion_Carrito(
	Id_Carrito BIGINT NOT NULL,
	Id_Producto BIGINT NOT NULL,
	Fecha DATE NOT NULL,
	Cantidad_Producto INT NOT NULL,

	
	CONSTRAINT FK_CARRITO_DEVOLUCION_CARRITO FOREIGN KEY (Id_Carrito)
	REFERENCES Operaciones.Carrito_Venta(Id_Carrito),
	CONSTRAINT FK_PRODUCTO_DEVOLUCION_CARRITO FOREIGN KEY (Id_Producto)
	REFERENCES Articulo.Producto(Id_Producto)
)

Select id_producto,nombre_producto, REPLACE(CAST(precio_publico_producto AS numeric)::text, '€', '')
, REPLACE(CAST(precio_publico_proveedor AS numeric)::text, '€', '')
,color,stock FROM Articulo.Producto
ORDER BY Id_Producto ASC

SELECT D.Num_Orden,D.Cantidad,D.SubTotal,P.Nombre_Producto,
P.Precio_Publico_Proveedor FROM Articulo.Producto P,Operaciones.Detalle_Orden D
WHERE D.Id_Producto=P.Id_Producto;

SELECT C.Id_Carrito,Cl.Nombre_Cliente,C.Forma_De_Pago,C.Fecha_Venta,C.Total_Carrito,T.Banco,T.Numero_Tarjeta,Cl.Id_Cliente
FROM Operaciones.Carrito_Venta C,Usuario.Cliente Cl,Datos.Tarjeta_Cliente T
WHERE C.Id_Tarjeta_Cliente=T.Id_Tarjeta AND T.Id_Cliente=Cl.Id_Cliente
ORDER BY C.Id_Carrito

SELECT CONCAT(C.Id_Carrito,' - ',Cl.Nombre_Cliente),D.Cantidad,D.SubTotal,P.Nombre_Producto,P.Precio_Publico_Producto,P.Id_Producto,D.Id_Carrito
FROM Operaciones.Detalle_Carrito D,Operaciones.Carrito_Venta C,Usuario.Cliente Cl,Datos.Tarjeta_Cliente T,Articulo.Producto P
WHERE C.Id_Tarjeta_Cliente=T.Id_Tarjeta AND T.Id_Cliente=Cl.Id_Cliente AND P.Id_Producto=D.Id_Producto
ORDER BY C.Id_Carrito

SELECT D.Num_Orden,D.Cantidad,D.SubTotal,P.Nombre_Producto,P.Precio_Publico_Proveedor FROM Articulo.Producto P,Operaciones.Detalle_Orden D
WHERE D.Id_Producto=P.Id_Producto

/*CHECK NUMERICO*/
ALTER TABLE Articulo.Producto
ADD CONSTRAINT CK_STOCK
CHECK(
    Stock >= 0
);
/*CHECK CADENAS*/
ALTER TABLE Operaciones.Carrito_Venta
ADD CONSTRAINT CK_FORMA_DE_PAGO
CHECK(
    Forma_De_Pago IN ('Debito','Credito')
);
/*CHECK UNIQUE*/
ALTER TABLE Usuario.Proveedor
ADD CONSTRAINT UQ_NOMBRE_PROVEEDOR
UNIQUE (Nombre_Provedoor);

ALTER TABLE Usuario.Proveedor
ADD CONSTRAINT UQ_Correo_Electronico_PROVEEDOR
UNIQUE (Correo_Electronico);

ALTER TABLE Usuario.Cliente
ADD CONSTRAINT UQ_Correo_Electronico_CLIENTE
UNIQUE (Correo_Electronico);

/*TRIGGERS*/
--SUBTOTAL OPERACIONES.DETALLE_ORDEN Se dispara de DETALLE_ORDEN

CREATE OR REPLACE FUNCTION actualizar_subtotal_detalle_orden()
    RETURNS TRIGGER AS $$
DECLARE
    precio MONEY;
BEGIN
	SELECT Precio_Publico_Proveedor INTO precio
    FROM Articulo.Producto
    WHERE Id_Producto = NEW.Id_Producto;
	Update Operaciones.Detalle_Orden 
	SET SubTotal=precio::money*NEW.Cantidad::int
	WHERE Id_Producto=NEW.Id_Producto AND SubTotal IS NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_actualizar_subtotal_detalle_orden
AFTER INSERT OR UPDATE ON Operaciones.Detalle_Orden
FOR EACH ROW
EXECUTE FUNCTION actualizar_subtotal_detalle_orden();


--STOCK ARTICULO.PRODUCTO Se dispara de DETALLE_ORDEN

CREATE OR REPLACE FUNCTION actualizar_stock_producto()
    RETURNS TRIGGER AS $$
BEGIN
	
    IF TG_OP = 'INSERT' THEN
        UPDATE Articulo.Producto
        SET Stock = Stock + NEW.Cantidad
        WHERE Id_Producto = NEW.Id_Producto;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Articulo.Producto
        SET Stock = Stock - OLD.Cantidad
        WHERE Id_Producto = OLD.Id_Producto;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.Id_Producto <> OLD.Id_Producto THEN
            UPDATE Articulo.Producto
            SET Stock = Stock - OLD.Cantidad
            WHERE Id_Producto = OLD.Id_Producto;
            
            UPDATE Articulo.Producto
            SET Stock = Stock + NEW.Cantidad
            WHERE Id_Producto = NEW.Id_Producto;
        ELSE
            UPDATE Articulo.Producto
            SET Stock = Stock + (NEW.Cantidad - OLD.Cantidad)
            WHERE Id_Producto = NEW.Id_Producto;
        END IF;
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_actualizar_stock_producto
AFTER INSERT OR UPDATE OR DELETE ON Operaciones.Detalle_Orden
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_producto();

--TOTAL OPERACIONES.ORDEN Se dispara de DETALLE_ORDEN

CREATE OR REPLACE FUNCTION actualizar_total_orden()
    RETURNS TRIGGER AS $$
DECLARE
    total_money MONEY;
BEGIN
   
   IF TG_OP = 'INSERT' THEN
        SELECT SUM(SubTotal) INTO total_money
        FROM Operaciones.Detalle_Orden
        WHERE Num_Orden = NEW.Num_Orden;
        
        IF total_money IS NULL THEN
            total_money := 0.00;
        END IF;
        
        UPDATE Operaciones.Orden
        SET Total = total_money
        WHERE Num_Orden = NEW.Num_Orden;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
        SELECT SUM(SubTotal) INTO total_money
        FROM Operaciones.Detalle_Orden
        WHERE Num_Orden = OLD.Num_Orden;
        
        IF total_money IS NULL THEN
            total_money := 0.00;
        END IF;
        
        UPDATE Operaciones.Orden
        SET Total = total_money
        WHERE Num_Orden = OLD.Num_Orden;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_actualizar_total_orden
AFTER INSERT OR UPDATE OR DELETE ON Operaciones.Detalle_Orden
FOR EACH ROW
EXECUTE FUNCTION actualizar_total_orden();
	--PRUEBAS TRIGGERS DETALLE_ORDEN

SELECT * FROM Articulo.Producto ORDER BY Id_Producto ASC

INSERT INTO Operaciones.Detalle_Orden(Num_Orden,Id_Producto,Cantidad,SubTotal)
VALUES(2,5,20,NULL)

delete from Operaciones.Detalle_Orden

SELECT proname FROM pg_proc WHERE proname LIKE 'actualizar%';

SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'Detalle_Orden';


SELECT C.Nombre_Cliente,O.Id_Carrito 
FROM Operaciones.Carrito_Venta O,Usuario.Cliente C,Datos.Tarjeta_Cliente T 
WHERE C.Id_Cliente=T.Id_Cliente AND T.Id_Tarjeta=O.Id_Tarjeta_Cliente 
ORDER BY O.Id_Carrito ASC

--STOCK ARTICULO.PRODUCTO Se dispara de DETALLE_CARRITO
CREATE OR REPLACE FUNCTION actualizar_stock_carrito_Detalle_Carrito()
    RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Articulo.Producto
        SET Stock = Stock - NEW.Cantidad
        WHERE Id_Producto = NEW.Id_Producto;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Articulo.Producto
        SET Stock = Stock + OLD.Cantidad
        WHERE Id_Producto = OLD.Id_Producto;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.Id_Producto <> OLD.Id_Producto THEN
            UPDATE Articulo.Producto
            SET Stock = Stock - OLD.Cantidad
            WHERE Id_Producto = OLD.Id_Producto;
            
            UPDATE Articulo.Producto
            SET Stock = Stock + NEW.Cantidad
            WHERE Id_Producto = NEW.Id_Producto;
        ELSE
			IF NEW.Cantidad>OLD.Cantidad THEN
			
            UPDATE Articulo.Producto
        	SET Stock = Stock - (NEW.Cantidad - OLD.Cantidad) 
       		WHERE Id_Producto = NEW.Id_Producto;
			
			ELSE
			
			UPDATE Articulo.Producto
        	SET Stock = Stock + (OLD.Cantidad - NEW.Cantidad)
       		WHERE Id_Producto = NEW.Id_Producto;
			END IF;
        END IF;
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_actualizar_stock_carrito_Detalle_Carrito
AFTER INSERT OR UPDATE OR DELETE ON Operaciones.Detalle_Carrito
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_carrito_Detalle_Carrito();
--SUBTOTAL OPERACIONES.DETALLE_CARRITO Se dispara de DETALLE_CARRITO

CREATE OR REPLACE FUNCTION actualizar_subtotal_detalle_carrito()
    RETURNS TRIGGER AS $$
DECLARE
    precio MONEY;
BEGIN
	SELECT Precio_Publico_Producto INTO precio
    FROM Articulo.Producto
    WHERE Id_Producto = NEW.Id_Producto;
	Update Operaciones.Detalle_Carrito
	SET SubTotal=precio::money*NEW.Cantidad::int
	WHERE Id_Producto=NEW.Id_Producto AND SubTotal IS NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_actualizar_subtotal_detalle_carrito
AFTER INSERT OR UPDATE ON Operaciones.Detalle_Carrito
FOR EACH ROW
EXECUTE FUNCTION actualizar_subtotal_detalle_carrito();

--TOTAL OPERACIONES.CARRITO_VENTA Se dispara de DETALLE_CARRITO

CREATE OR REPLACE FUNCTION actualizar_total_carrito_venta()
    RETURNS TRIGGER AS $$
DECLARE
    total_money MONEY;
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT SUM(SubTotal) INTO total_money
        FROM Operaciones.Detalle_Carrito
        WHERE Id_Carrito = NEW.Id_Carrito;
        
        IF total_money IS NULL THEN
            total_money := 0.00;
        END IF;
        
        UPDATE Operaciones.Carrito_Venta
        SET Total_Carrito = total_money
        WHERE Id_Carrito = NEW.Id_Carrito;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
        SELECT SUM(SubTotal) INTO total_money
        FROM Operaciones.Detalle_Carrito
        WHERE Id_Carrito = OLD.Id_Carrito;
        
        IF total_money IS NULL THEN
            total_money := 0.00;
        END IF;
        
        UPDATE Operaciones.Carrito_Venta
        SET Total_Carrito = total_money
        WHERE Id_Carrito = OLD.Id_Carrito;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_actualizar_total_carrito_venta
AFTER INSERT OR UPDATE OR DELETE ON Operaciones.Detalle_Carrito
FOR EACH ROW
EXECUTE FUNCTION actualizar_total_carrito_venta();

	--PRUEBAS TRIGGERS DETALLE_CARRITO

SELECT * FROM Articulo.Producto ORDER BY Id_Producto ASC

SELECT * FROM Operaciones.Detalle_Carrito

INSERT INTO Operaciones.Detalle_Carrito (Id_Carrito,Id_Producto,Cantidad,SubTotal)
VALUES(3,14,1,NULL)

delete from Operaciones.Detalle_Carrito

--STOCK ARTICULO.PRODUCTO Se dispara de DEVOLUCION_CARRITO

CREATE OR REPLACE FUNCTION actualizar_stock_devolucion_carrito()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF NEW.Cantidad_Producto <= (
        SELECT Cantidad
        FROM Operaciones.Detalle_Carrito
        WHERE Id_Producto = NEW.Id_Producto
        AND Id_Carrito = NEW.Id_Carrito
    ) THEN
        UPDATE Operaciones.Detalle_Carrito
        SET cantidad = cantidad - NEW.Cantidad_Producto,
            subTotal = NULL
        WHERE id_carrito = NEW.id_carrito
        AND id_producto = NEW.id_producto;
        RETURN NEW;
    END IF;
  END IF;

  IF (TG_OP = 'UPDATE') THEN
  	IF NEW.Cantidad_Producto <= ((
        SELECT Cantidad
        FROM Operaciones.Detalle_Carrito
        WHERE Id_Producto = NEW.Id_Producto
        AND Id_Carrito = NEW.Id_Carrito
    )+OLD.Cantidad_Producto)
	THEN
    IF NEW.Id_Producto <> OLD.Id_Producto THEN
        UPDATE Operaciones.Detalle_Carrito
        SET cantidad = cantidad - OLD.Cantidad_Producto,
            subTotal = NULL
        WHERE Id_Producto = OLD.Id_Producto;

        UPDATE Operaciones.Detalle_Carrito
        SET cantidad = cantidad + NEW.Cantidad,
            subTotal = NULL
        WHERE Id_Producto = NEW.Id_Producto;
    ELSE
        IF NEW.Cantidad_Producto > OLD.Cantidad_Producto THEN
            UPDATE Operaciones.Detalle_Carrito
            SET cantidad = cantidad - (NEW.Cantidad_Producto - OLD.Cantidad_Producto),
                subTotal = NULL
            WHERE Id_Producto = NEW.Id_Producto;
        ELSE
            UPDATE Operaciones.Detalle_Carrito
            SET cantidad = cantidad + (OLD.Cantidad_Producto - NEW.Cantidad_Producto),
                subTotal = NULL
            WHERE Id_Producto = NEW.Id_Producto;
        END IF;
    END IF;
    RETURN NEW;
	END IF;
  END IF;

  IF (TG_OP = 'DELETE') THEN
    UPDATE Operaciones.Detalle_Carrito
    SET cantidad = cantidad + OLD.Cantidad_Producto,
        subTotal = NULL
    WHERE id_carrito = OLD.id_carrito
      AND id_producto = OLD.id_producto;
    RETURN OLD;
  END IF;

  RAISE EXCEPTION 'No tienes tantos productos';
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER tr_actualizar_stock_devolucion_carrito
AFTER INSERT OR DELETE OR UPDATE ON Operaciones.Devolucion_Carrito
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_devolucion_carrito();


SELECT O.Id_Carrito,O.Cantidad_Producto,O.Fecha,P.Nombre_Producto,P.Precio_Publico_Producto
FROM Operaciones.Devolucion_Carrito O,Articulo.Producto P
WHERE O.Id_Producto=P.Id_Producto


delete from Operaciones.Devolucion_Carrito



/*CREACION USERS*/
  	/*con permisos de administrador osea a todo*/
CREATE USER pedro WITH PASSWORD '123';
ALTER USER pedro WITH SUPERUSER;
SELECT * FROM Usuario.Cliente
	/*otro con otorgación de privilegios*/
DROP USER andrea;
CREATE USER andrea WITH PASSWORD '123';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Usuario TO andrea;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Articulo TO andrea;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Datos TO andrea;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Usuario TO andrea;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Articulo TO andrea;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Datos TO andrea;
GRANT USAGE ON SCHEMA Usuario TO andrea;
GRANT USAGE ON SCHEMA Articulo TO andrea;
GRANT USAGE ON SCHEMA Datos TO andrea;
SELECT * FROM Usuario.Cliente
INSERT INTO Usuario.Cliente (nombre_cliente,correo_electronico)
	VALUES('Pedro','pedro@pedrito.com');
	/*otro con denegación de privilegios nomas va poder hacer select*/
CREATE USER pablo WITH PASSWORD '123';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Usuario TO pablo;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Operaciones TO pablo;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Articulo TO pablo;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Datos TO pablo;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Usuario TO pablo;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Operaciones TO pablo;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Articulo TO pablo;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Datos TO pablo;
GRANT USAGE ON SCHEMA Usuario TO pablo;
GRANT USAGE ON SCHEMA Operaciones TO pablo;
GRANT USAGE ON SCHEMA Articulo TO pablo;
GRANT USAGE ON SCHEMA Datos TO pablo;
REVOKE DELETE,INSERT,UPDATE,TRUNCATE ON ALL TABLES IN SCHEMA Usuario FROM pablo;
REVOKE DELETE,INSERT,UPDATE,TRUNCATE ON ALL TABLES IN SCHEMA Operaciones FROM pablo;
REVOKE DELETE,INSERT,UPDATE,TRUNCATE ON ALL TABLES IN SCHEMA Articulo FROM pablo;
REVOKE DELETE,INSERT,UPDATE,TRUNCATE ON ALL TABLES IN SCHEMA Datos FROM pablo;
SELECT * FROM Usuario.Cliente
INSERT INTO Usuario.Cliente (nombre_cliente,correo_electronico)
	VALUES('Pedro','pedro@pedrito.com');

SELECT usename AS "Nombre de usuario"
FROM pg_user;

SET ROLE postgres;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
SELECT * FROM pg_extension WHERE extname = 'pgcrypto';

  
SELECT usename, passwd FROM pg_shadow;

ALTER USER andrea WITH PASSWORD 'andrea123';--Inserta,Elimina,Modifica sobre las tablas que esten en los schemas Articulo,Datos,Usuario
ALTER USER pablo WITH PASSWORD 'paloma123';--Solo puede ver las tablas
ALTER USER pedro WITH PASSWORD 'peter123';--SuperUsuario

--REPORTE 1
SELECT COUNT (O.Num_Orden),P.Nombre_Provedoor  FROM Operaciones.Orden O, Usuario.Proveedor P
WHERE O.Id_Proveedor=P.Id_Proveedor
GROUP BY P.Nombre_Provedoor

SELECT COUNT(O.Num_Orden), P.Nombre_Provedoor
FROM Operaciones.Orden O
INNER JOIN Usuario.Proveedor P ON O.Id_Proveedor = P.Id_Proveedor
GROUP BY P.Nombre_Provedoor;
--REPORTE 2
SELECT N.Numero
FROM Datos.Telefono_Cliente N,Usuario.Cliente C
WHERE N.Id_Cliente=C.Id_Cliente

SELECT N.Numero
FROM Datos.Telefono_Cliente N
WHERE N.Id_Cliente IN (SELECT C.Id_Cliente FROM Usuario.Cliente C);

