select *
  from tab_grupos
 where grupo in (1, 2, 3, 4, 5, 6, 11);

  with venta_mensual as (
    select i.cod_art, to_char(d.fecha, 'YYYY-MM') as fecha
         , sum(i.cantidad) as cantidad
         , sum(round(case :moneda
                       when d.moneda then i.neto
                       else (case d.moneda
                               when 'S' then i.neto / d.import_cam
                               else i.neto * d.import_cam
                             end)
                     end, 2)) as neto
      from docuvent d
           join itemdocu i
                on d.tipodoc = i.tipodoc
                  and d.serie = i.serie
                  and d.numero = i.numero
     where nvl(d.estado, '0') != '9'
       and d.tipodoc in ('01', '03')
       and i.cod_art in ('KIT AUT MS 87773 A', 'KIT MH FS 95320 MLS')
       and d.fecha between add_months(trunc(sysdate, 'MM'), - :promedio_meses)
       and trunc(sysdate, 'MM') - 1
     group by i.cod_art, to_char(d.fecha, 'YYYY-MM')
     order by i.cod_art, to_char(d.fecha, 'YYYY-MM')
    )
select cod_art
     , nvl(round(sum(cantidad) / :promedio_meses, 2), 0) as prom_venta_cant
     , nvl(round(sum(neto) / :promedio_meses, 2), 0) as prom_venta_importe
  from venta_mensual
 group by cod_art;

-- campania_excedentes
  with venta_mensual as (
    select i.cod_art, to_char(d.fecha, 'YYYY-MM') as fecha
         , sum(i.cantidad) as cantidad
         , sum(round(case :moneda
                       when d.moneda then i.neto
                       else (case d.moneda
                               when 'S' then i.neto / d.import_cam
                               else i.neto * d.import_cam
                             end)
                     end, 2)) as neto
      from docuvent d
           join itemdocu i
                on d.tipodoc = i.tipodoc
                  and d.serie = i.serie
                  and d.numero = i.numero
     where nvl(d.estado, '0') != '9'
       and d.tipodoc in ('01', '03')
--        and i.cod_art in ('KIT AUT MS 87773 A', 'KIT MH FS 95320 MLS')
       and d.fecha between add_months(trunc(sysdate, 'MM'), - :promedio_meses)
       and trunc(sysdate, 'MM') - 1
     group by i.cod_art, to_char(d.fecha, 'YYYY-MM')
     order by i.cod_art, to_char(d.fecha, 'YYYY-MM')
    )
     , promedio_venta as (
    select cod_art
         , nvl(round(sum(cantidad) / :promedio_meses, 2), 0) as prom_venta_cant
         , nvl(round(sum(neto) / :promedio_meses, 2), 0) as prom_venta_importe
      from venta_mensual
     group by cod_art
    )
     , escala_excedente as (
    select cod_escala, meses, dscto, bono, dsc_escala
         , meses as meses_desde
         , lead(meses - 1, 1, 9999999) over (order by meses) as meses_hasta
      from escala_excedentes
    )
     , stock_actual as (
    select cod_art, sum(stock) as stock
      from almacen
     where cod_alm = 'F0'
     group by cod_art
    )
     , stock_al as (
    select d.cod_art, sum(decode(d.ing_sal, 'S', (d.cantidad * -1), d.cantidad)) as stock
      from kardex_d d
     where d.estado != '9'
       and d.cod_alm = 'F0'
       and d.fch_transac <= :fecha_al
     group by d.cod_art
    )
     , consolidado as (
    select a.cod_art, a.descripcion, a.cod_lin, l.descripcion as dsc_linea, l.grupo
         , l.descripcion as dsc_grupo
         , nvl(p.prom_venta_cant, 0) as prom_venta_cant
         , nvl(p.prom_venta_importe, 0) as prom_venta_importe
         , nvl(s.stock, 0) as stock
         , nvl(prom_venta_cant, 0) * 12 as stock_simulado_12_meses
         , nvl(prom_venta_cant, 0) * 24 as stock_simulado_24_meses
         , nvl(prom_venta_cant, 0) * 36 as stock_simulado_36_meses
         , round(s.stock / nvl(prom_venta_cant, 0.01), 2) as meses_stock_simulado
      from articul a
           left join tab_lineas l on a.cod_lin = l.linea
           left join tab_grupos g on l.grupo = g.grupo
           left join stock_al s on a.cod_art = s.cod_art
           left join promedio_venta p on a.cod_art = p.cod_art
     where l.grupo in ('1', '2', '3', '4', '5', '6', '11')
       and nvl(s.stock, 0) > 0
       and not exists(
       select cod_art
         from kardex_d k
        where nvl(k.estado, '0') != '9'
          and k.tp_transac = '11'
          and k.fch_transac >= to_date('01/01/2023', 'dd/mm/yyyy')
          and a.cod_art = k.cod_art
       )
    )
select cod_art, descripcion, cod_lin, dsc_linea, grupo, dsc_grupo, stock
     , prom_venta_cant, prom_venta_importe, meses_stock_simulado, stock_simulado_12_meses
     , greatest(stock - stock_simulado_12_meses, 0) as stock_exceso, e.dsc_escala
     , e.dscto, e.bono
  from consolidado c
       join escala_excedente e
            on c.meses_stock_simulado between e.meses_desde and e.meses_hasta;
--   where stock != stock_al;

select to_date('09/10/2023', 'dd/mm/yyyy') from dual;

select cod_art
  from kardex_d
 where nvl(estado, '0') != '9'
   and tp_transac = '11'
   and fch_transac >= to_date('01/01/2023', 'dd/mm/yyyy')
 group by cod_art;
--    and cod_art = 'M 400.1018'

select distinct k.tp_transac, t.descripcion
  from kardex_d k
       join transacciones_almacen t on k.tp_transac = t.tp_transac
 where cod_art = 'FS 1535-1 MLS'
   and fch_transac >= to_date('01/01/2023', 'dd/mm/yyyy');


  with venta_mensual as (
    select i.cod_art, to_char(d.fecha, 'YYYY-MM') as fecha
         , sum(i.cantidad) as cantidad
         , sum(round(case :p_moneda
                       when d.moneda then i.neto
                       else (case d.moneda
                               when 'S' then i.neto / d.import_cam
                               else i.neto * d.import_cam
                             end)
                     end, 2)) as neto
      from docuvent d
           join itemdocu i
                on d.tipodoc = i.tipodoc
                  and d.serie = i.serie
                  and d.numero = i.numero
     where nvl(d.estado, '0') != '9'
--        and d.tipodoc in ('01', '03')
       and i.cod_art in ('FS 80232 MLS')
       and d.fecha between add_months(trunc(sysdate, 'MM'), - :p_prom_meses)
       and trunc(sysdate, 'MM') - 1
     group by i.cod_art, to_char(d.fecha, 'YYYY-MM')
     order by i.cod_art, to_char(d.fecha, 'YYYY-MM')
    )
     , promedio_venta as (
    select cod_art
         , nvl(round(sum(cantidad) / :p_prom_meses, 2), 0) as prom_venta_cant
         , nvl(round(sum(neto) / :p_prom_meses, 2), 0) as prom_venta_importe
      from venta_mensual
     group by cod_art
    )
select *
  from promedio_venta;


select cod_art, consumo as cantidad, 0 as neto
  from consumo_piezas
 where ano = 2023
   and mes between 6 and 9
   and cod_art = 'FS 80232 MLS';


select extract(month from add_months(sysdate, -4)) as desde
     , extract(month from add_months(sysdate, -1)) as hasta
  from dual;

select *
  from vw_kardex_valorizado_almacenes
 where cod_art = 'FS 80232 MLS';

select max(fch_transac)
  from kardex_d
 where tp_transac in ('11', '17')
   and cod_alm = 'F0'
   and cod_art = 'FS 80232 MLS'
 group by cod_art;


  with venta_mensual as (
    select cod_art, consumo as cantidad, 0 as neto
      from consumo_piezas
     where ano = extract(year from sysdate)
       and mes between extract(month from add_months(sysdate, -4)) and extract(month from add_months(sysdate, -1))
    )
     , promedio_venta as (
    select cod_art
         , nvl(round(sum(cantidad) / :p_prom_meses, 2), 0) as prom_venta_cant
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
       and d.fch_transac <= :p_fecha_al
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
--          , case prom_venta_cant
--              when 0 then 0
--              else round(s.stock / nvl(prom_venta_cant, 0.01), 2)
--            end as meses_stock_simulado
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
                       to_date('01/01/2023', 'dd/mm/yyyy')
 where cod_art = 'FSP 88185 MLS';

select *
  from almacen
 where cod_art = 'RP 100-60038-N';
