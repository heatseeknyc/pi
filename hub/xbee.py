import serial
import logging
import time

BYTEORDER = 'big'
START = b'\x7E'
AT_TYPE = b'\x08'
DUMMY_ID = b'x'

def checksum(bites):
    s = 0
    for bite in bites:
        s = (s + bite) & 0xFF
    return s

def int_from_bytes(bites):
    return int.from_bytes(bites, byteorder=BYTEORDER)

def int_to_bytes(n, length):
    return n.to_bytes(length, byteorder=BYTEORDER)

def byte(b):
    return bytes((b,))

def frame(body):
    return (START
            + int_to_bytes(len(body), 2)
            + body
            + byte(0xFF - checksum(body)))

def at_frame(command, data=b''):
    return frame(AT_TYPE
                 + DUMMY_ID
                 + command.encode('ascii')
                 + data)

def send(frame, xb):
    print('sending {}'.format(frame))
    xb.write(frame)
    print('sent')

def update_sleep_period(sleep_period):
    with serial.Serial('/dev/ttyAMA0') as xb:
        logging.info('connected to xbee.')

        # 'aggregate' all cells in default broadcast mode to point to us instead:
        # TODO do this more than once?
        send(at_frame('AG', b'\xFF\xFF'), xb)
        time.sleep(0.1)

        # set sleep period, and write changes to persistent flash
        send(at_frame('SP', int_to_bytes(sleep_period, 4)), xb)
        time.sleep(0.1)
        send(at_frame('WR'), xb)
        time.sleep(0.1)

        send(at_frame('SP'), xb)  # read new sleep period into db
