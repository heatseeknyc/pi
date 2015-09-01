import binascii
import functools
import logging
import time


def hexlify(bites):
    return binascii.hexlify(bites).decode('ascii')

def forever(f):
    @functools.wraps(f)
    def g(*args, **kwargs):
        while True:
            try:
                f(*args, **kwargs)
            except Exception:
                logging.exception('error, retrying...')
                time.sleep(1)
    return g

def main(f):
    if f.__module__ == '__main__':
        logging.info('starting...')
        f()
    return f
