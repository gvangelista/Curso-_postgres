create table arma
(
id            serial       not null,
numero_serie  varchar(104),
descricao     varchar(256) not null,
tipo          varchar(1)   not null,
ativo         boolean      not null default true,
criado_em     timestamp(6) not null default now(),
modificado_em timestamp(6) default now(),
constraint pk_arma primary key (id)
);

create table tipo_crime
(
id                 serial       not null,
nome                varchar(104) not null,
tempo_minimo_prisao smallint,
tempo_maximo_prisao smallint,
tempo_prescricao    smallint,
ativo              boolean      not null default true,
criado_em          timestamp(6) not null default now(),
modificado_em       timestamp(6) default now(),
constraint pk_tipo_crime primary key (id)
);
create unique index ak_tipo_crime_nome on tipo_crime (nome);

create table pessoa
(
id              serial       not null,
nome           varchar(104) not null,
cpf            varchar(11)  not null,
telefone        varchar(11)  not null,
data_nascimento date         not null,
endereco        varchar(256) not null,
ativo          boolean      not null default true,
criado_em       timestamp(6) not null default now(),
modificado_em   timestamp(6) default now(),
constraint pk_pessoa primary key (id)
);
create unique index ak_pessoa_cpf on pessoa (cpf);

create table crime
(
id            serial       not null,
id_tipo_crime integer      not null,
data          timestamp(6) not null,
local         varchar(256) not null,
observacao    text,
ativo         boolean      not null default true,
criado_em     timestamp(6) not null default now(),
modificado_em timestamp(6) default now(),
constraint pk_crime primary key (id),
constraint fk_crime_tipo_crime foreign key (id_tipo_crime) references tipo_crime (id)
);


create table crime_pessoa
(
id            serial       not null,
id_crime      integer      not null,
id_pessoa     integer      not null,
tipo          varchar(1)   not null,
ativo         boolean      not null default true,
criado_em     timestamp(6) not null default now(),
modificado_em timestamp(6) default now(),
constraint pk_crime_pessoa primary key (id),
constraint fk_crime_pessoa_crime foreign key (id_crime) references crime (id),
constraint fk_crime_pessoa_pessoa foreign key (id_pessoa) references pessoa (id)
);
create unique index ak_pessoa_crime on crime_pessoa (id_pessoa, id_crime);

