begin
  excedentes.elimina();
  excedentes.carga_tabla(
      p_moneda => 'D'
    , p_prom_meses => 4
    , p_fecha_al => sysdate
  );
end;

select *
  from campania_excedentes
 where cod_art = 'FS 80232 MLS';

select *
  from campania_excedentes
 where dsc_escala is null;

select distinct cod_grupo, dsc_grupo
  from campania_excedentes
 order by cod_grupo;

select dsc_escala, cod_escala
  from escala_excedentes
 order by cod_escala;

select cod_art, dsc_art, cod_lin, dsc_lin, cod_grupo, dsc_grupo, stock, prom_venta_cant
     , precio_neto, meses_stock_simulado, stock_simulado_escala_1, stock_simulado_escala_2
     , stock_simulado_escala_3, stock_exceso, cod_escala, dsc_escala, dscto, bono
  from campania_excedentes;

select *
  from campania_excedentes
 where cod_art = 'FS 50030 TG';
