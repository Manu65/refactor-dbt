with
base_customers as (
    select * from {{source('jaffle_shop','customers')}} 
),
customers as (
    select 
        id,
        first_name || ' ' || last_name as name, 
        last_name,
        first_name
      from base_customers

)

select * from customers