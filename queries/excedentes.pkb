create or replace package body excedentes as

  procedure carga_tabla(
    p_moneda     varchar2
  , p_prom_meses number
  , p_fecha_al   date
  ) is
  begin
    insert into campania_excedentes( cod_art, dsc_art, cod_lin, dsc_lin, cod_grupo, dsc_grupo, stock
                                   , prom_venta_cant, precio_neto, meses_stock_simulado
                                   , stock_simulado_escala_1, stock_simulado_escala_2
                                   , stock_simulado_escala_3, stock_exceso, valor_exceso, cod_escala
                                   , dsc_escala, dscto, bono, fch_ult_compra)
      with venta_mensual as (
        select cod_art, consumo as cantidad, 0 as neto
          from consumo_piezas
         where ano = extract(year from sysdate)
           and mes between extract(month from add_months(sysdate, -4)) and extract(month from add_months(sysdate, -1))
        )
         , promedio_venta as (
        select cod_art
             , nvl(round(sum(cantidad) / p_prom_meses, 2), 0) as prom_venta_cant
          from venta_mensual
         group by cod_art
        )
         , escala_excedente as (
        select cod_escala, meses, dscto, bono, dsc_escala
             , meses as meses_desde
             , lead(meses - 1, 1, 9999999) over (order by meses) as meses_hasta
          from escala_excedentes
        )
         , stock_al as (
        select d.cod_art, sum(decode(d.ing_sal, 'S', (d.cantidad * -1), d.cantidad)) as stock
          from kardex_d d
         where d.estado != '9'
           and d.cod_alm = 'F0'
           and d.fch_transac <= p_fecha_al
         group by d.cod_art
        )
         , ultimo_ing_produccion as (
        select cod_art, max(fch_transac) as fch_ult_compra
          from kardex_d
         where tp_transac in ('11', '17')
           and cod_alm = 'F0'
         group by cod_art
        )
         , consolidado as (
        select a.cod_art, a.descripcion, a.cod_lin, l.descripcion as dsc_linea, l.grupo
             , g.descripcion as dsc_grupo, u.fch_ult_compra
             , f_lista_precio_venta(a.cod_art) as precio_neto
             , nvl(p.prom_venta_cant, 0) as prom_venta_cant
             , nvl(s.stock, 0) as stock
             , nvl(prom_venta_cant, 0) * 12 as stock_simulado_12_meses
             , nvl(prom_venta_cant, 0) * 24 as stock_simulado_24_meses
             , nvl(prom_venta_cant, 0) * 36 as stock_simulado_36_meses
             , round(s.stock / greatest(nvl(prom_venta_cant, 0.01), 0.01), 2) as meses_stock_simulado
          from articul a
               left join tab_lineas l on a.cod_lin = l.linea
               left join tab_grupos g on l.grupo = g.grupo
               left join stock_al s on a.cod_art = s.cod_art
               left join promedio_venta p on a.cod_art = p.cod_art
               left join ultimo_ing_produccion u on a.cod_art = u.cod_art
         where l.grupo in ('1', '2', '3', '4', '5', '6', '11')
           and nvl(s.stock, 0) > 0
        )
    select cod_art, descripcion, cod_lin, dsc_linea, grupo, dsc_grupo, stock, prom_venta_cant
         , precio_neto, meses_stock_simulado, stock_simulado_12_meses
         , stock_simulado_24_meses, stock_simulado_36_meses
         , greatest(stock - stock_simulado_12_meses, 0) as stock_exceso
         , precio_neto * greatest(stock - stock_simulado_12_meses, 0) as valor_exceso
         , cod_escala, e.dsc_escala, e.dscto, e.bono, fch_ult_compra
      from consolidado c
           left join escala_excedente e
                     on floor(c.meses_stock_simulado) between e.meses_desde and e.meses_hasta
                       and nvl(fch_ult_compra, to_date('01/01/2000', 'dd/mm/yyyy')) <
                           to_date('01/01/2023', 'dd/mm/yyyy');
  end;

  procedure elimina is
  begin
    delete from campania_excedentes;
  end;
end excedentes;
