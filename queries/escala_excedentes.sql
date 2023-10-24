drop table pevisa.escala_excedentes
  cascade constraints;

create table pevisa.escala_excedentes (
  cod_escala number(3),
  meses      number(4)    not null,
  dsc_escala varchar2(50) not null,
  dscto      number(6),
  bono       number(6, 2) not null
)
  tablespace pevisad;


create unique index pevisa.idx_escala_excedentes
  on pevisa.escala_excedentes(cod_escala) tablespace pevisax;


create or replace public synonym escala_excedentes for pevisa.escala_excedentes;


alter table pevisa.escala_excedentes
  add (
    constraint pk_escala_excedentes
      primary key (cod_escala)
        using index pevisa.idx_escala_excedentes
        enable validate
    );


grant delete, insert, select, update on pevisa.escala_excedentes to sig_roles_invitado;
