with

-- import CTEs sources
orders as (
    select * from {{ref('stg_jaffle_shop__orders')}}
),
customers as (
    select * from {{ref('stg_jaffle_shop__customers')}}
),
payments as (
    select 
    * 
    from {{ref('stg_stripe__payments')}}
    where payment_status != 'fail'
),
customer_order_history as (
    select 
        a.customer_id,
        min(order_date) as first_order_date,
        min(
            case 
            when a.order_status NOT IN ('returned','return_pending') 
            then order_date 
        end) as first_non_returned_order_date,
        max(
            case 
            when a.order_status NOT IN ('returned','return_pending') 
            then order_date 
        end) as most_recent_non_returned_order_date,
        COALESCE(max(user_order_seq),0) as order_count,
        COALESCE(count(case 
                       when a.order_status != 'returned' 
                       then 1 
                    end),0) as non_returned_order_count,
        sum(case 
            when a.order_status NOT IN ('returned','return_pending') 
            then c.payment_amount 
            else 0 
        end) as total_lifetime_value,
        sum(case 
            when a.order_status NOT IN ('returned','return_pending') 
            then c.payment_amount
            else 0 
        end)/
        NULLIF(count(case 
                     when a.order_status NOT IN ('returned','return_pending') 
                     then 1 
                    end)
                ,0) as avg_non_returned_order_value,
        array_agg(distinct a.order_id) as order_ids

    from orders a
    left outer join payments  c
    on a.order_id = c.order_id
    where a.order_status NOT IN ('pending') 
    group by a.customer_id
),
final as (
    select 
    orders.order_id,
    orders.customer_id,
    last_name as surname,
    first_name as givenname,
    first_order_date,
    order_count,
    total_lifetime_value,
    payment_amount as order_value_dollars,
    orders.order_status,
    payments.payment_status 
from orders
join customers customers
on orders.customer_id = customers.id
join customer_order_history
on orders.customer_id = customer_order_history.customer_id
left outer join payments 
on orders.order_id = payments.order_id
)

select * from final
