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
    departamento int not null,
    canthab int,
    foreign key (departamento) references departamento on delete restrict
);
