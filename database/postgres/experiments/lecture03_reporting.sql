\set ON_ERROR_STOP 1

begin;

\echo 'Lecture 3: baseline across all four strategies'
select * from captured_revenue_for_day('2026-04-29', 'DKK');
select revenue_date, currency, captured_amount
from captured_revenue_daily
where revenue_date = '2026-04-29';
select revenue_date, currency, captured_amount
from captured_revenue_daily_mv
where revenue_date = '2026-04-29';

insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status, created_utc
) values (
    'PAYMENT-LECTURE3', 'USER-1', 'TICKET-1', 'lecture3-captured',
    10.00, 'DKK', 'Captured', '2026-04-29 10:00:00+00'
);

\echo 'After captured insert: trigger summary changes immediately; MV is stale'
select * from captured_revenue_for_day('2026-04-29', 'DKK');
select * from captured_revenue_daily where revenue_date = '2026-04-29';
select * from captured_revenue_daily_mv where revenue_date = '2026-04-29';

update payments set status = 'Failed' where id = 'PAYMENT-LECTURE3';
update payments set status = 'Captured' where id = 'PAYMENT-LECTURE3';
update payments set status = 'Refunded' where id = 'PAYMENT-LECTURE3';
delete from payments where id = 'PAYMENT-LECTURE3';

\echo 'After failed/captured/refunded/delete transitions: direct and function agree with trigger summary'
select * from captured_revenue_for_day('2026-04-29', 'DKK');
select * from captured_revenue_daily where revenue_date = '2026-04-29';

\echo 'Refresh makes the materialized view current'
refresh materialized view captured_revenue_daily_mv;
select * from captured_revenue_daily_mv where revenue_date = '2026-04-29';

do $$
begin
    begin
        insert into payments (
            id, user_id, ticket_id, external_payment_reference,
            amount, currency, status
        ) values (
            'PAYMENT-LECTURE3-DUP', 'USER-1', 'TICKET-1',
            'gateway-capture-0001', 1.00, 'DKK', 'Captured'
        );
        raise exception 'duplicate external reference was accepted';
    exception when unique_violation then
        raise notice 'expected failure: duplicate external payment reference rejected';
    end;
end;
$$;

rollback;