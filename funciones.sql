drop table if exists localidad;
drop table if exists departamento;
drop table if exists provincia;
drop table if exists pais;
CREATE TABLE pais
(
    id_pais serial not null primary key,
    pais text not null
);


CREATE TABLE provincia
(
    provincia int not null primary key,
    id_pais int not null,
    foreign key (id_pais) references pais on delete restrict
);


CREATE TABLE departamento
(
    id_departamento serial not null primary key,
    departamento text not null,
    provincia int not null,
    foreign key (provincia) references provincia on delete restrict
);


CREATE TABLE  localidad
(
    id_localidad serial not null primary key,
    nombre text not null,
    id_departamento int not null,
    canthab int,
    foreign key (id_departamento) references departamento on delete restrict
);

drop table if exists intermedia;
CREATE TABLE intermedia
(
    nombre text not null,
    pais text not null,
    provincia int not null,
    departamento text not null,
    canthab int
);

create or replace function doInsertarEnOtrasTablas()
returns trigger as
    $$
    begin
        if not exists(select * from pais where pais = new.pais) then
            insert into pais (pais) values (new.pais);
        end if;
        if not exists(select * from provincia where provincia = new.provincia) then
            insert into provincia (provincia, id_pais) values (new.provincia, (select id_pais from pais where pais = new.pais));
        end if;
        if not exists(select * from departamento where departamento = new.departamento) then
            insert into departamento (departamento, provincia) values (new.departamento, (select provincia from provincia where provincia = new.provincia));
        end if;
        update localidad
            set canthab = new.canthab
        where
              nombre = new.nombre and
              id_departamento = (select id_departamento from departamento 
                                    where departamento = new.departamento and departamento.provincia = (select provincia from provincia
                                                                                                            where provincia.provincia=new.provincia
                                                                                                  and provincia.id_pais = (select id_pais from pais
                                                                                                                            where pais.pais = new.pais)));
        if not found then 
            insert into localidad (nombre, id_departamento, canthab)
            values (new.nombre, (select id_departamento from departamento 
                                    where departamento = new.departamento and departamento.provincia = (select provincia from provincia
                                                                                                            where provincia.provincia=new.provincia
                                                                                                  and provincia.id_pais = (select id_pais from pais
                                                                                                                            where pais.pais = new.pais))),new.canthab);
            
        end if;
        return null;
    end
    $$
LANGUAGE plpgsql;

create trigger insertarEnOtrasTablas
    after insert on intermedia
    for each row
    execute procedure doInsertarEnOtrasTablas();

\copy intermedia from localidades.csv header delimiter ',' csv;

select * from localidad