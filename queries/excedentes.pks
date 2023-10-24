create or replace package excedentes as

  procedure carga_tabla(
    p_moneda     varchar2
  , p_prom_meses number
  , p_fecha_al   date
  );

  procedure elimina;

end excedentes;
