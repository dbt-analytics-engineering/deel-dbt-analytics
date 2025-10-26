{{
    config(
        materialized='table'
        )
}}

with transaction_features as (
    select
        external_ref
        , country
        , currency
        , amount
        , usd_amount
        , cvv_provided
        , state
        , chargeback
        , date_time
        , ref
        -- Feature engineering: transaction counts per country per day
        , count(*) over (
            partition by country, date(date_time)
        ) as transactions_today_by_country
        -- Average transaction amount per country
        , avg(amount) over (
            partition by country
        ) as avg_country_amount
        , avg(usd_amount) over (
            partition by country
        ) as avg_country_usd_amount
    from {{ ref('base_globepay_transactions') }}
),

risk_factors as (
    select
        external_ref
        , country
        , currency
        , amount
        , usd_amount
        , cvv_provided
        , state
        , chargeback
        , date_time
        , ref
        , transactions_today_by_country
        , avg_country_amount
        , avg_country_usd_amount
        -- Risk Factor 1: Large transactions without CVV (high risk)
        , case
            when not cvv_provided and amount > avg_country_amount * 2 then 0.8
            when not cvv_provided and amount > avg_country_amount * 1.5 then 0.6
            when not cvv_provided then 0.4
            else 0.2
          end as cvv_risk_score
        -- Risk Factor 2: Unusual transaction volume per country
        , case
            when transactions_today_by_country > 50 then 0.7
            when transactions_today_by_country > 30 then 0.5
            else 0.2
          end as volume_risk_score
        -- Risk Factor 3: Large accepted transactions (potential fraud)
        , case
            when amount > 10000 and state = 'ACCEPTED' then 0.6
            when amount > 5000 and state = 'ACCEPTED' then 0.4
            when state = 'ACCEPTED' then 0.1
            else 0.0
          end as large_transaction_risk_score
        -- Risk Factor 4: Amount significantly above country average
        , case
            when usd_amount > avg_country_usd_amount * 3 then 0.8
            when usd_amount > avg_country_usd_amount * 2 then 0.5
            else 0.2
          end as amount_deviation_risk_score
    from transaction_features
)

select
    external_ref
    , country
    , currency
    , amount
    , usd_amount
    , cvv_provided
    , state
    , chargeback
    , date_time
    , ref
    , transactions_today_by_country
    , avg_country_amount
    , avg_country_usd_amount
    , cvv_risk_score
    , volume_risk_score
    , large_transaction_risk_score
    , amount_deviation_risk_score
    -- Overall risk score (weighted average)
    , round(
        (cvv_risk_score * 0.4) +
        (volume_risk_score * 0.2) +
        (large_transaction_risk_score * 0.2) +
        (amount_deviation_risk_score * 0.2),
        3
    ) as overall_risk_score
    -- Risk level categorization
    , case
        when round(
            (cvv_risk_score * 0.4) +
            (volume_risk_score * 0.2) +
            (large_transaction_risk_score * 0.2) +
            (amount_deviation_risk_score * 0.2),
            3
        ) >= 0.7 then 'HIGH'
        when round(
            (cvv_risk_score * 0.4) +
            (volume_risk_score * 0.2) +
            (large_transaction_risk_score * 0.2) +
            (amount_deviation_risk_score * 0.2),
            3
        ) >= 0.4 then 'MEDIUM'
        else 'LOW'
    end as risk_level
from risk_factors
