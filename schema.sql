
create table temperatures (
       cell_id not null,
       adc not null,
       sleep_period not null,
       time not null default (strftime('%s', 'now')),
       relayed_time
);

create table status as select
       null as xbee_id_high,
       null as xbee_id_low,
       1 as sleep_period;
