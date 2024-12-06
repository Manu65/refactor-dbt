with

base_payments as (
    select * from {{source('stripe','payment')}} 
),
payments as (
    select 
        id as payment_id,
        orderid order_id,
        status as payment_status,
        ROUND(amount/100.0,2) payment_amount
     from base_payments
)

select * from payments