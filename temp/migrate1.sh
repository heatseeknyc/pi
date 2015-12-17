sudo apt-get update
sudo apt-get -y install sqlite3

sqlite3 ~/heatseeknyc.db <<EOF
alter table temperatures rename to temperatures_old;
create table temperatures (
       cell_id not null,
       adc not null,
       sleep_period not null,
       time not null default (strftime('%s', 'now')),
       relayed_time
);
EOF

sudo supervisorctl restart receiver;
sudo supervisorctl restart transmitter;
