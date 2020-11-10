
-- Ejercicio 1
DROP TABLE IF EXISTS localidad;
DROP TABLE IF EXISTS departamento;
DROP TABLE IF EXISTS provincia;
DROP TABLE IF EXISTS pais;
DROP TABLE IF EXISTS intermedia;

CREATE TABLE pais
(
    id_pais SERIAL NOT NULL PRIMARY KEY,
    pais TEXT NOT NULL
);

CREATE TABLE provincia
(
    provincia INT NOT NULL PRIMARY KEY,
    id_pais   INT NOT NULL,
    FOREIGN KEY (id_pais) REFERENCES pais ON DELETE RESTRICT
);

CREATE TABLE departamento
(
    id_departamento SERIAL NOT NULL PRIMARY KEY,
    departamento TEXT NOT NULL,
    provincia INT NOT NULL,
    FOREIGN KEY (provincia) REFERENCES provincia ON DELETE RESTRICT
);

CREATE TABLE localidad
(
    id_localidad SERIAL NOT NULL PRIMARY KEY,
    nombre TEXT NOT NULL,
    id_departamento INT NOT NULL,
    canthab         INT,
    FOREIGN KEY (id_departamento) REFERENCES departamento ON DELETE RESTRICT
);

CREATE TABLE intermedia
(
    nombre TEXT NOT NULL,
    pais TEXT NOT NULL,
    provincia INT NOT NULL,
    departamento TEXT NOT NULL,
    canthab INT
);

CREATE OR replace FUNCTION doinsertarenotrastablas()
returns TRIGGER AS
    $$
    BEGIN 
        -- Si no existe el pais lo agrego
        IF NOT EXISTS (SELECT * FROM pais WHERE pais = new.pais) 
        THEN
            INSERT INTO pais(pais) 
                   VALUES(new.pais);
        END IF;

        -- Si no existe provincia con pais buscando su id, lo agrego con ese id
        IF NOT EXISTS (SELECT *
                       FROM   provincia
                       WHERE  provincia = new.provincia
                       AND    id_pais = (SELECT id_pais
                                         FROM   pais
                                         WHERE  pais.pais = new.pais)
                      )
        THEN
            INSERT  INTO provincia(provincia, id_pais)
                    VALUES(new.provincia,
                           (SELECT id_pais
                            FROM   pais
                            WHERE  pais = new.pais
                           )
                          );
        END IF;

        -- Si no existe el departamento con una provincia y pais buscando su respectivo id, lo agrego con esos ids
        IF NOT EXISTS (SELECT *
                       FROM   departamento
                       WHERE  departamento = new.departamento
                       AND    departamento.provincia = (SELECT provincia.provincia
                                                        FROM   provincia
                                                        WHERE  provincia.provincia = new.provincia
                                                        AND    provincia.id_pais = (SELECT id_pais
                                                                                    FROM   pais
                                                                                    WHERE  pais.pais = new.pais)
                                                       )
                      )
        THEN
            INSERT INTO departamento(departamento, provincia)
                   VALUES(new.departamento,
                          (SELECT provincia.provincia
                           FROM   provincia
                           WHERE  provincia.provincia = new.provincia
                           AND    provincia.id_pais = (SELECT id_pais
                                                       FROM   pais
                                                       WHERE  pais.pais = new.pais
                                                      )
                          )
                         );
        END IF;

        -- Primero intentamos actualizar la cantidad de habitantes de la localidad con sus respectivos id de departamento, provincia y pais.
        -- Si no existe se agrega la localidad
        UPDATE localidad
            SET    canthab = new.canthab
            WHERE  nombre = new.nombre
            AND    id_departamento =(SELECT id_departamento
                                     FROM   departamento
                                     WHERE  departamento = new.departamento
                                     AND    departamento.provincia = (SELECT provincia.provincia
                                                                      FROM   provincia
                                                                      WHERE  provincia.provincia = new.provincia
                                                                      AND    provincia.id_pais = (SELECT id_pais
                                                                                                  FROM   pais
                                                                                                  WHERE  pais.pais = new.pais)));
            IF NOT found THEN
                INSERT INTO localidad(nombre, id_departamento, canthab)
                       VALUES(new.nombre,
                              (SELECT id_departamento
                               FROM   departamento
                               WHERE  departamento = new.departamento
                               AND    departamento.provincia = (SELECT provincia.provincia
                                                                FROM   provincia
                                                                WHERE  provincia.provincia = new.provincia
                                                                AND    provincia.id_pais = (SELECT id_pais
                                                                                            FROM   pais
                                                                                            WHERE  pais.pais = new.pais)
                                                               )
                              ),
                              new.canthab
                              );
        END IF;
        RETURN NULL;
    END
    $$ 
LANGUAGE plpgsql;

CREATE TRIGGER insertarenotrastablas 
    AFTER INSERT ON intermedia 
    FOR each row
    EXECUTE PROCEDURE doinsertarenotrastablas();

\copy intermedia FROM localidades.csv header delimiter ',' csv;


-- Ejercicio 2
CREATE OR replace FUNCTION dodeleteenotrastablas()
returns TRIGGER AS
    $$
    BEGIN
        -- Primero se borra la localidad
        DELETE
        FROM   localidad
        WHERE  nombre = old.nombre
        AND    id_departamento = (SELECT departamento.id_departamento
                                  FROM   departamento
                                  WHERE  departamento.departamento = old.departamento
                                  AND    departamento.provincia = (SELECT provincia.provincia
                                                                   FROM   provincia
                                                                   WHERE  provincia.provincia = old.provincia
                                                                   AND    provincia.id_pais = (SELECT id_pais
                                                                                               FROM   pais
                                                                                               WHERE  pais.pais = old.pais
                                                                                              )
                                                                  )
                                 );
        
        -- Si el departamento no tiene ninguna localidad que dependa de este, se borra
        IF NOT EXISTS (SELECT *
                       FROM   localidad
                       WHERE  id_departamento =(SELECT departamento.id_departamento
                                                FROM   departamento
                                                WHERE  departamento.departamento = old.departamento
                                                AND    departamento.provincia = (SELECT provincia.provincia
                                                                                 FROM   provincia
                                                                                 WHERE  provincia.provincia = old.provincia
                                                                                 AND    provincia.id_pais = (SELECT id_pais
                                                                                                             FROM   pais
                                                                                                             WHERE  pais.pais = old.pais
                                                                                                            )
                                                                                )
                                               )
                      )
        THEN
            DELETE
            FROM   departamento
            WHERE  id_departamento = (SELECT departamento.id_departamento
                                      FROM   departamento
                                      WHERE  departamento.departamento = old.departamento
                                      AND    departamento.provincia = (SELECT provincia.provincia
                                                                       FROM   provincia
                                                                       WHERE  provincia.provincia = old.provincia
                                                                       AND    provincia.id_pais = (SELECT id_pais
                                                                                                   FROM   pais
                                                                                                   WHERE  pais.pais = old.pais
                                                                                                  )
                                                                      )
                                     );
          
        END IF;

        -- Si la provincia no tiene ningun departamento que dependa de esta, se borra
        IF NOT EXISTS (SELECT *
                       FROM   departamento
                       WHERE  provincia = (SELECT provincia.provincia
                                           FROM   provincia
                                           WHERE  provincia.provincia = old.provincia
                                           AND    provincia.id_pais = (SELECT id_pais
                                                                       FROM   pais
                                                                       WHERE  pais.pais = old.pais
                                                                      )
                                          )
                      )
        THEN
            DELETE
            FROM   provincia
            WHERE  provincia.provincia = (SELECT provincia.provincia
                                          FROM   provincia
                                          WHERE  provincia.provincia = old.provincia
                                          AND    provincia.id_pais = (SELECT id_pais
                                                                      FROM   pais
                                                                      WHERE  pais.pais = old.pais
                                                                     )
                                         );
        
        END IF;

        -- Si el pais no tiene ninguna provincia que dependa de este, se borra
        IF NOT EXISTS (SELECT *
                       FROM   provincia
                       WHERE  id_pais = (SELECT id_pais
                                         FROM   pais
                                         WHERE  pais.pais = old.pais
                                        )
                      )
        THEN
            DELETE
            FROM   pais
            WHERE  id_pais = (SELECT id_pais
                              FROM   pais
                              WHERE  pais.pais = old.pais
                             );
        END IF;
        return NULL;
    end
    $$
LANGUAGE plpgsql;

CREATE TRIGGER deleteenotrastablas
    AFTER DELETE ON intermedia
    FOR each row
    EXECUTE PROCEDURE dodeleteenotrastablas(); 
