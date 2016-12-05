import logging
import time
import json
import requests
import serial

from . import common, database, xbee

logging.basicConfig(level=logging.INFO)


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
                            xbee.update_sleep_period(sleep_period)
                            break
                else:
                    logging.error('bad response: %s', response)

            time.sleep(10)
