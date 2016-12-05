import argparse
import logging
import time
import serial

from . import common, xbee


@common.main
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('sleep_period', type=int)
    args = parser.parse_args()

    xbee.update_sleep_period(args.sleep_period)
