with tblyearmonthlist as (
    select 
        extract(year from dt)::int as year, 
        extract(month from dt)::int as month
    from (
        select generate_series(
            to_date('01-04-2025', 'DD-MM-YYYY'),
            to_date('31-03-2026', 'DD-MM-YYYY'),
            interval '1 month'
        ) as dt
    ) as date_series
),
tblmonthlysales as (
    select 
        extract(year from v.date)::int as year, 
        extract(month from v.date)::int as month,
        sum(abs(a.amount)) as amount
    from trn_accounting a
    join trn_voucher v on v.guid = a.guid
    join mst_ledger l on l.name = a.ledger
    join mst_group g on g.name = l.parent
    where g.primary_group = 'Sales Accounts'
      and v.date >= to_date('01-04-2025', 'DD-MM-YYYY')
      and v.date <= to_date('31-03-2026', 'DD-MM-YYYY')
    group by 
        extract(year from v.date), 
        extract(month from v.date)
),
tblmonthlypurchase as (
    select 
        extract(year from v.date)::int as year, 
        extract(month from v.date)::int as month,
        sum(abs(a.amount)) as amount
    from trn_accounting a
    join trn_voucher v on v.guid = a.guid
    join mst_ledger l on l.name = a.ledger
    join mst_group g on g.name = l.parent
    where g.primary_group = 'Purchase Accounts'
      and v.date >= to_date('01-04-2025', 'DD-MM-YYYY')
      and v.date <= to_date('31-03-2026', 'DD-MM-YYYY')
    group by 
        extract(year from v.date), 
        extract(month from v.date)
)
select 
	-- l.year, 
    TO_CHAR(TO_DATE(l.month::text, 'MM'), 'Month') AS month,
    coalesce(round(s.amount/10000000,2), 0) as monthly_sales,
	coalesce(round(sum(s.amount) over (
        order by l.year, l.month
        rows between unbounded preceding and current row
    )/10000000,2), 0) as total_sales,
	coalesce(round(p.amount/10000000,2), 0) as monthly_purchase,
	coalesce(round(sum(p.amount) over (
        order by l.year, l.month
        rows between unbounded preceding and current row
    )/10000000,2), 0) as total_purchase
from tblyearmonthlist l
left join tblmonthlysales s 
    on l.year = s.year and l.month = s.month
left join tblmonthlypurchase p 
    on l.year = p.year and l.month = p.month
where coalesce(round(s.amount/10000000,2), 0) <> 0
order by l.year, l.month;
