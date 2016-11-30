import logging
import time
import json
import requests
import serial

from . import common, database, xbee

logging.basicConfig(level=logging.INFO)

def send(frame, xb):
    print('sending {}'.format(frame))
    xb.write(frame)
    print('sent')

def update_sleep_period(sleep_period):
    with serial.Serial('/dev/ttyAMA0') as xb:
        logging.info('connected to xbee.')

        # 'aggregate' all cells in default broadcast mode to point to us instead:
        # TODO do this more than once?
        send(xbee.at_frame('AG', b'\xFF\xFF'), xb)
        time.sleep(0.1)

        # set sleep period, and write changes to persistent flash
        send(xbee.at_frame('SP', xbee.int_to_bytes(sleep_period, 4)), xb)
        time.sleep(0.1)
        send(xbee.at_frame('WR'), xb)
        time.sleep(0.1)

        send(xbee.at_frame('SP'), xb)  # read new sleep period into db


@common.main
def main():
    with database.Database() as db:
        logging.info('connected to database.')

        while True:
            if db.get_sleep_period() == 1:
                xbee_id = common.hexlify(db.get_xbee_id())

                response = requests.get('http://relay-dev.heatseek.org/hubs/{}/commands'.format(xbee_id))

                if response.status_code == 200:
                    for command in response.json():
                        action, param = command
                        if action == 'change_sleep_period':
                            sleep_period = int(param)
                            logging.error('updating sleep period to %s', sleep_period)
                            update_sleep_period(sleep_period)
                            break
                else:
                    logging.error('bad response: %s', response)

            time.sleep(10)
