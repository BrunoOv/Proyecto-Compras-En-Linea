CREATE DATABASE ComprasEnLinea

USE ComprasEnLinea

CREATE SCHEMA Usuario
CREATE SCHEMA Operaciones
CREATE SCHEMA Articulo
CREATE SCHEMA Datos

CREATE TABLE Usuario.Cliente(
	Id_Cliente BIGINT IDENTITY(1,1) NOT NULL,
	Nombre_Cliente VARCHAR(50) NOT NULL,
	Correo_Electronico VARCHAR(50) NOT NULL,

	CONSTRAINT PK_CLIENTE PRIMARY KEY (Id_Cliente) 
)

CREATE TABLE Usuario.Proveedor(
	Id_Proveedor BIGINT IDENTITY(1,1) NOT NULL,
	Correo_Electronico VARCHAR(50) NOT NULL,
	Nombre_Proveedor VARCHAR(50) NOT NULL,
	Domicilio_Fiscal VARCHAR(100) NOT NULL,

	CONSTRAINT PK_PROVEEDOR PRIMARY KEY (Id_Proveedor) 
)

CREATE TABLE Articulo.Producto(
	Id_Producto BIGINT IDENTITY(1,1) NOT NULL,
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
	Id_Tarjeta BIGINT IDENTITY(1,1) NOT NULL,
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

CREATE TABLE Operaciones.Carrito_Venta(
	Id_Carrito BIGINT IDENTITY(1,1) NOT NULL,
	Id_Tarjeta_Cliente BIGINT NOT NULL,
	Forma_De_Pago VARCHAR(50) NOT NULL,
	Fecha_Venta DATE NOT NULL,
	Total_Carrito MONEY,

	CONSTRAINT PK_CARRITO PRIMARY KEY (Id_Carrito),
	CONSTRAINT FK_TARJETA_CLIENTE_CARRITO FOREIGN KEY (Id_Tarjeta_Cliente)
	REFERENCES Datos.Tarjeta_Cliente(Id_Tarjeta)
)

CREATE TABLE Operaciones.Orden(
	Num_Orden BIGINT IDENTITY(1,1) NOT NULL,
	Id_Proveedor BIGINT NOT NULL,
	Fecha_Orden DATE NOT NULL,
	Total MONEY,

	CONSTRAINT PK_ORDEN PRIMARY KEY (Num_Orden),
	CONSTRAINT FK_PROVEEDOR_ORDEN FOREIGN KEY (Id_Proveedor)
	REFERENCES Usuario.Proveedor(Id_Proveedor)
)

ALTER TABLE Operaciones.Orden ALTER COLUMN Total MONEY NULL;
EXEC sp_unbindrule 'RL_ORDEN_TOTAL';

CREATE RULE RL_ORDEN_TOTAL AS @Total >= 0 OR @Total IS NULL
EXEC sp_bindrule 'RL_ORDEN_TOTAL','Operaciones.Orden.Total';

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



CREATE RULE RL_STOCK AS @Stock >= 0
EXEC sp_bindrule 'RL_STOCK','Articulo.Producto.Stock'



CREATE RULE RL_FORMA_DE_PAGO AS @Forma_de_Pago IN ('Debito','Credito')
EXEC sp_bindrule 'RL_FORMA_DE_PAGO','Operaciones.Carrito_Venta.Forma_De_Pago'

DELETE RL_FORMA_DE_PAGO

CREATE TRIGGER TR_ACTUALIZA_STOCK_TOTAL_SUBTOTAL_DETALLE_CARRITO ON Operaciones.Detalle_Carrito
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	UPDATE Operaciones.Detalle_Carrito
	SET SubTotal = Operaciones.Detalle_Carrito.Cantidad * Precio_Publico_Producto
	FROM inserted
	JOIN Articulo.Producto ON inserted.Id_Producto = Articulo.Producto.Id_Producto
	WHERE Operaciones.Detalle_Carrito.Id_Carrito = inserted.Id_Carrito AND Operaciones.Detalle_Carrito.Id_Producto = inserted.Id_Producto;
	
	UPDATE Operaciones.Carrito_Venta
    SET Total_Carrito = (SELECT SUM(SubTotal) FROM Operaciones.Detalle_Carrito O WHERE O.Id_Carrito = Operaciones.Carrito_Venta.Id_Carrito)
    WHERE Id_Carrito IN (SELECT Id_Carrito FROM Operaciones.Detalle_Carrito)

	UPDATE Articulo.Producto
    SET Stock = Stock - i.Cantidad
    FROM Articulo.Producto p
    INNER JOIN inserted i ON p.Id_Producto = i.Id_Producto

	DELETE FROM Operaciones.Detalle_Carrito
	WHERE Cantidad < 1

END;


CREATE TRIGGER TR_ACTUALIZA_CANTIDAD_INSERTAR ON Operaciones.Devolucion_Carrito
AFTER INSERT
AS
BEGIN
	
	UPDATE Operaciones.Detalle_Carrito
	SET Cantidad = Cantidad - inserted.Cantidad_Producto
	FROM inserted
	WHERE Operaciones.Detalle_Carrito.Id_Producto = inserted.Id_Producto

END;

CREATE TRIGGER TR_ACTUALIZA_CANTIDAD_DELETE ON Operaciones.Devolucion_Carrito
AFTER DELETE
AS
BEGIN
	
	UPDATE Operaciones.Detalle_Carrito
	SET Cantidad = Cantidad + deleted.Cantidad_Producto
	FROM deleted
	WHERE Operaciones.Detalle_Carrito.Id_Producto = deleted.Id_Producto

END;

CREATE TRIGGER TR_ACTUALIZAR_CANTIDAD
ON Operaciones.Devolucion_Carrito AFTER UPDATE
AS
BEGIN

	SET NOCOUNT ON;

    IF UPDATE(Cantidad_Producto) 
	BEGIN
        UPDATE Operaciones.Detalle_Carrito 
		SET Cantidad = Cantidad + (inserted.Cantidad_Producto - deleted.Cantidad_Producto)
        WHERE Id_Producto = inserted.Id_Producto AND Id_Carrito = inserted.Id_Carrito;
    END
END;



CREATE TRIGGER TR_ACTUALIZAR_CANTIDAD_MODIFICAR
ON Operaciones.Devolucion_Carrito
AFTER UPDATE
AS
BEGIN
    UPDATE Detalle_Carrito
    SET Cantidad = CASE 
                        WHEN inserted.Cantidad_Producto > deleted.Cantidad_Producto 
                        THEN Cantidad - (inserted.Cantidad_Producto - deleted.Cantidad_Producto)
                        ELSE Cantidad + (deleted.Cantidad_Producto - inserted.Cantidad_Producto)
                    END
    FROM Detalle_Carrito
    INNER JOIN Devolucion_Carrito ON Detalle_Carrito.Id_Carrito = Devolucion_Carrito.Id_Carrito
                                 AND Detalle_Carrito.Id_Producto = Devolucion_Carrito.Id_Producto
    INNER JOIN inserted ON inserted.Id_Carrito = Devolucion_Carrito.Id_Carrito
                        AND inserted.Id_Producto = Devolucion_Carrito.Id_Producto
    INNER JOIN deleted ON deleted.Id_Carrito = Devolucion_Carrito.Id_Carrito
                       AND deleted.Id_Producto = Devolucion_Carrito.Id_Producto
END




CREATE TRIGGER TR_ACTUALIZA_STOCK_TOTAL_SUBTOTAL_DEVOLUCION_CARRITO ON Operaciones.Devolucion_Carrito
AFTER INSERT, UPDATE, DELETE
AS
BEGIN

	UPDATE Operaciones.Detalle_Carrito
	SET SubTotal = Operaciones.Detalle_Carrito.Cantidad * Precio_Publico_Producto
	FROM inserted
	JOIN Articulo.Producto ON inserted.Id_Producto = Articulo.Producto.Id_Producto
	WHERE Operaciones.Detalle_Carrito.Id_Carrito = inserted.Id_Carrito AND Operaciones.Detalle_Carrito.Id_Producto = inserted.Id_Producto;
	
	UPDATE Operaciones.Carrito_Venta
    SET Total_Carrito = (SELECT SUM(SubTotal) FROM Operaciones.Detalle_Carrito O WHERE O.Id_Carrito = Operaciones.Carrito_Venta.Id_Carrito)
    WHERE Id_Carrito IN (SELECT Id_Carrito FROM Operaciones.Detalle_Carrito)

	UPDATE Articulo.Producto
    SET Stock = Stock + i.Cantidad_Producto
    FROM Articulo.Producto p
    INNER JOIN inserted i ON p.Id_Producto = i.Id_Producto

END;






SELECT SUM(Subtotal) FROM Operaciones.Detalle_Orden WHERE Operaciones.Detalle_Orden.Num_Orden = 19


--FUCIONAMOS LOS 3 TRIGGER QUE AFECTAN A LA TABLA PRODUCTO, DETALLE ORDEN Y ORDEN--
CREATE TRIGGER TR_ACTUALIZA_STOCK_TOTAL_SUBTOTAL_DETALLE_ORDEN ON Operaciones.Detalle_Orden
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	UPDATE Operaciones.Detalle_Orden
	SET SubTotal = Operaciones.Detalle_Orden.Cantidad * Precio_Publico_Proveedor
	FROM inserted
	JOIN Articulo.Producto ON inserted.Id_Producto = Articulo.Producto.Id_Producto
	WHERE Operaciones.Detalle_Orden.Num_Orden = inserted.Num_Orden AND Operaciones.Detalle_Orden.Id_Producto = inserted.Id_Producto;
	
	UPDATE Operaciones.Orden
    SET Total = (SELECT SUM(SubTotal) FROM Operaciones.Detalle_Orden O WHERE O.Num_Orden = Operaciones.Orden.Num_Orden)
    WHERE Num_Orden IN (SELECT Num_Orden FROM Operaciones.Detalle_Orden)

	UPDATE Articulo.Producto
    SET Stock = Stock + i.Cantidad
    FROM Articulo.Producto p
    INNER JOIN inserted i ON p.Id_Producto = i.Id_Producto

END;



SELECT SUM(Subtotal) FROM Operaciones.Detalle_Orden O, Operaciones.Orden WHERE O.Num_Orden = Operaciones.Orden.Num_Orden



SELECT Subtotal FROM Operaciones.Detalle_Orden O,Operaciones.Orden WHERE O.Num_Orden = Operaciones.Orden.Num_Orden

DROP TRIGGER TR_ACTUALIZA_SUBTOTAL

/*CONSULTAS*/

SELECT * FROM Usuario.Cliente
SELECT * FROM Usuario.Proveedor

SELECT C.Nombre_Cliente, C.Correo_Electronico FROM Usuario.Cliente C, Datos.Telefono_Cliente T WHERE C.Id_Cliente=T.Id_Cliente
SELECT T.Id_Cliente, T.Numero, C.Nombre_Cliente, C.Correo_Electronico FROM Usuario.Cliente C, Datos.Telefono_Cliente T WHERE C.Id_Cliente=T.Id_Cliente

TRUNCATE TABLE Operaciones.Orden;
TRUNCATE TABLE Operaciones.Detalle_Orden;

DELETE FROM Operaciones.Orden;
DELETE FROM Operaciones.Detalle_Orden;

DELETE FROM Operaciones.Carrito_Venta;

INSERT INTO Operaciones.Orden (Id_Proveedor, Fecha_Orden,Total) VALUES (5,'2023-09-23',0)

SELECT * FROM Operaciones.Orden

INSERT INTO Operaciones.Detalle_Orden (Num_Orden,Id_Producto,Cantidad) VALUES (23,4,1)
INSERT INTO Operaciones.Detalle_Orden (Num_Orden,Id_Producto,Cantidad) VALUES (19,4,1)

SELECT * FROM Operaciones.Detalle_Orden

SELECT * FROM Operaciones.Orden

SELECT CONCAT(C.Id_Carrito, ' - ', U.Nombre_Cliente) as identificador_carrito, D.Cantidad,cast(D.SubTotal AS DECIMAL(10,2)) as subtotal,  P.Nombre_Producto, 
	cast(P.Precio_Publico_Producto AS DECIMAL(10,2)) as precio_publico
FROM Operaciones.Detalle_Carrito D, Articulo.Producto P,Operaciones.Carrito_Venta C, Usuario.Cliente U, Datos.Tarjeta_Cliente T
WHERE C.Id_Carrito = D.Id_Carrito AND D.Id_Producto = P.Id_Producto AND U.Id_Cliente = T.Id_Cliente AND T.Id_Tarjeta = C.Id_Tarjeta_Cliente 

SELECT P.Id_Producto, P.Nombre_Producto
FROM Articulo.Producto P,Operaciones.Detalle_Carrito O
WHERE P.Id_Producto=O.Id_Producto AND O.Id_Carrito=18
