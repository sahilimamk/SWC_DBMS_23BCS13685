--Q1 Active User Retention

select 7 as month , count(distinct(user_id)) as monthly_active_users
from user_actions u where event_date>='2022-07-01' and event_date<'2022-08-01' and 
exists(select 1 from user_actions p 
where p.user_id=u.user_id and p.event_date>='2022-06-01' and p.event_date<'2022-07-01' )

--Q2 Repeated Payments

select count(*) as payment_count from transactions a join transactions b on a.merchant_id=b.merchant_id
and a.credit_card_id=b.credit_card_id and a.amount=b.amount
where b.transaction_timestamp<=a.transaction_timestamp + interval '10 minutes' and a.transaction_timestamp < b.transaction_timestamp
