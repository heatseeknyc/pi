import logging

import serial

from . import common, database, xbee


logging.basicConfig(level=logging.INFO)


def listen(xb, db):
    while True:  # read until start byte
        b = xb.read(1)
        if b == xbee.START: break
        logging.warn('expected start byte %s but got %s', xbee.START, b)
    length = xbee.int_from_bytes(xb.read(2))
    frame = xb.read(length)
    checksum, = xb.read(1)

    if xbee.checksum(frame) + checksum != 0xFF:
        raise Exception('frame checksum 0x%02X does not complement 0x%02X', xbee.checksum(frame), checksum)

    frame_type = frame[0]

    if frame_type == 0x88: # AT Command Response
        command = frame[2:4]
        status = frame[4]
        data = frame[5:]

        try: command = command.decode('ascii')
        except UnicodeDecodeError: pass

        if status != 0:
            logging.warn('AT%s failed with status %d', command, status)
        elif command in ('SH', 'SL'):
            if len(data) != 4:
                raise Exception('AT{} data should be 4 bytes, but was {}'.format(command, len(data)))
            logging.info('%s=%s', command, data)
            if command == 'SH': db.set_xbee_id_high(data)
            else: db.set_xbee_id_low(data)
        elif command == 'SP' and data:
            if len(data) != 4:
                raise Exception('ATSP data should be 4 bytes, but was {}'.format(len(data)))
            logging.info('SP=%d', xbee.int_from_bytes(data))
            db.set_sleep_period(xbee.int_from_bytes(data))
        else:
            logging.info('unhandled AT%s response', command)

    elif frame_type == 0x92: # Data Sample Rx Indicator
        # TODO properly handle digital and analog masks
        if len(frame) != 18:
            raise Exception('expected Rx frame with one sample to be 18 bytes, but was {}'.format(len(frame)))
        cell_id = frame[1:9]
        adc = xbee.int_from_bytes(frame[16:18])

        logging.info('cell_id=%s adc=0x%x', cell_id, adc)

        db.insert_temperature(cell_id, adc, db.get_sleep_period())

    else:
        logging.info('unhandled frame type 0x%02X', frame_type)


@common.main
def main():
    with serial.Serial('/dev/ttyAMA0') as xb, database.Database() as db:
        logging.info('connected to xbee and database.')
        while True:
            listen(xb, db)
