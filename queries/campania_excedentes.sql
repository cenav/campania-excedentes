drop table campania_excedentes cascade constraints;

create global temporary table pevisa.campania_excedentes (
  cod_art                 varchar2(30),
  dsc_art                 varchar2(100),
  cod_lin                 varchar2(4),
  dsc_lin                 varchar2(80),
  cod_grupo               number(3),
  dsc_grupo               varchar2(80),
  stock                   number(12, 2),
  prom_venta_cant         number(12, 2),
  precio_neto             number(14, 4),
  fch_ult_compra          date,
  meses_stock_simulado    number(12, 2),
  stock_simulado_escala_1 number(12, 2),
  stock_simulado_escala_2 number(12, 2),
  stock_simulado_escala_3 number(12, 2),
  stock_exceso            number(12, 2),
  valor_exceso            number(14, 4),
  cod_escala              number(3),
  dsc_escala              varchar2(50),
  dscto                   number(6),
  bono                    number(6, 2)
)
  on commit preserve rows;

create unique index pevisa.idx_campania_excedentes
  on pevisa.campania_excedentes(cod_art);

create index pevisa.idx_campania_excedentes_linea
  on pevisa.campania_excedentes(cod_lin);

create index pevisa.idx_campania_excedentes_grupo
  on pevisa.campania_excedentes(cod_grupo);

create index pevisa.idx_campania_excedentes_escala
  on pevisa.campania_excedentes(cod_escala);

create or replace public synonym campania_excedentes for pevisa.campania_excedentes;

alter table pevisa.campania_excedentes
  add (
    constraint pk_campania_excedentes
      primary key (cod_art)
        using index pevisa.idx_campania_excedentes
        enable validate
    );

grant delete, insert, select, update on pevisa.campania_excedentes to sig_roles_invitado;
