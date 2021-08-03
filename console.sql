---Transformar a tabela de venda particionada por ano. Lembre-se de verificar todos os anos possíveis para criar
--- partições de forma correta.

drop table sale_read;

create table public.sale_read
(
    id          integer      not null,
    id_customer integer      not null,
    id_branch   integer      not null,
    id_employee integer      not null,
    date        timestamp(6) not null,
    created_at  timestamp    not null,
    modified_at timestamp    not null,
    active      boolean      not null
) partition by range (date);

do
$$
    declare
        ano     integer;
        comando varchar;
    begin
        for ano in 1970..2021
            loop
                comando := format('create table sale_read_%s partition of sale_read for values from (%s) to (%s);',
                                  ano,
                                  quote_literal(concat(ano::varchar, '-01-01 00:00:00.000000')),
                                  quote_literal(concat(ano::varchar, '-12-31 23:59:59.999999'))
                    );
                execute comando;
            end loop;
    end;
$$;

create or replace function fn_popular_sale_read() returns trigger as
$$
begin
    insert into sale_read(id, id_customer, id_branch, id_employee, date, created_at, modified_at, active)
    values (new.id, new.id_customer, new.id_branch, new.id_employee, new.date, new.created_at, new.modified_at,
            new.active);
    return new;
end;
$$
    language plpgsql;

create trigger tg_popular_sale_read_update
    after update
    on sale
    for each row
execute function fn_popular_sale_read();

do
$$
    declare
        consulta record;
    begin
        for consulta in select * from sale
            loop
                update sale set id_customer = id_customer where id = consulta.id;
            end loop;
    end;
$$;

----Crie um PIVOT TABLE para saber o total vendido por grupo de produto por mês referente a um determinado ano.




select *
from crosstab(
$$
select  pg.name,
        date_part('month', s.date) as date,
        sum(si.quantity * p.sale_price) as total
from sale s
inner join sale_item si on s.id = si.id_sale
inner join product p on p.id = si.id_product
inner join product_group pg on pg.id = p.id_product_group
where date_part('year', s.date) = 2020
group by 1, 2
$$,
$$
select * from generate_series(1,12)
$$
         ) as (
               grupo varchar,Janeiro numeric,Fevereiro numeric,Marco numeric,Abril numeric,Maio numeric,Junho numeric,
             Julho numeric,Agosto numeric,Setembro numeric,Outubro numeric,Novembro numeric,Dezembro numeric
    );

---Crie um PIVOT TABLE para saber o total de clientes por bairro e zona;



select * from crosstab(
$$
select d.name,
       z.name,
       count(*) as clientes
from customer c
inner join district d on d.id = c.id_district
inner join zone z on z.id = d.id_zone
group by 1,2;
$$,
$$
select name from zone;
$$) as (bairro varchar, Norte numeric, Sul numeric, Leste numeric, Oeste numeric);

-- Crie uma coluna para saber o preço unitário do item de venda, crie
-- um script para atualizar os dados já existentes e logo em seguida uma
-- trigger para preencher o campo

Select * From sale_item;

alter table sale_item
    add column unit_price numeric(20, 3);

alter table sale_item
    drop column unit_price;


do
$$
 declare
    consulta record;
begin
        for consulta in (select si.*,( sum(si.quantity * p.sale_price)) as total
                         from sale_item si
                                  inner join product p on p.id = si.id_product
                         group by 1
        )
            loop
                update sale_item set unit_price = consulta.total where id = consulta.id;
            end loop;
    end;
$$;

create or replace function fn_populate_uprice() returns trigger as
$$
declare
    consulta record;
begin
for consulta in (select si.id, sum(si.quantity * p.sale_price) as total
                 from sale_item si
                    inner join product p on p.id = si.id_product
                 group by 1
                 order by 1 desc
                 limit 1
)
    loop
        update sale_item set unit_price = consulta.total WHERE id = consulta.id;
    end loop;
return new;
end;
$$
language plpgsql;



;

create trigger tg_populate_uprice
    after insert
    on sale_item
    for each row
execute function fn_populate_uprice();


-- Crie um campo para saber o total da venda, crie um script para
-- atualizar os dados já existentes, em seguida uma trigger para
-- preencher o campo de forma automática

select si.id_sale,
      sum(si.unit_price)
from sale_item si
group by 1;

select * from sale;

alter table sale
    add column sale_total numeric(20, 3);

alter table sale
    drop column sale_total;


select s.id,sum(si.unit_price) as total
    from sale s
    inner join sale_item si on s.id = si.id_sale
    group by 1;

do
$$
 declare
    consulta record;
begin
        for consulta in select s.id,sum(si.unit_price) as total
                            from sale s
                                inner join sale_item si on s.id = si.id_sale
                            group by 1
                            order by 1

            loop
                update sale set sale_total = consulta.total where id = consulta.id;
            end loop;
    end;
$$;

create or replace function fn_populate_sale_total() returns trigger as
$$
declare
    consulta record;
begin
    for consulta in select s.id,sum(si.unit_price) as total
                            from sale s
                                inner join sale_item si on s.id = si.id_sale
                            group by 1
                            order by 1
                            limit 1

    loop
        update sale set sale_total = consulta.total where id = consulta.id;
    end loop;
return new;
end;
$$
language plpgsql;


create trigger tg_populate_sale_total
    after insert
    on sale
    for each row
execute function fn_populate_sale_total();
