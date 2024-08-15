with this_model as (
    select sum(usd_amount) as this_model_amount
    from  {{ ref('analytics_globepay_transactions') }}
),
    upstream_model as (
    select sum(usd_amount) as upstream_model_amount
    from  {{ ref('base_globepay_transactions') }}
)
select *
from this_model 
cross join upstream_model
where this_model_amount <> upstream_model_amount