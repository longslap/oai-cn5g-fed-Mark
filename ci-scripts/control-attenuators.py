#!/usr/bin/env python3

import argparse
import logging
import usb.core
import usb.util
import sys
import time

logging.basicConfig(
    level=logging.DEBUG,
    stream=sys.stdout,
    format="[%(asctime)s] %(levelname)8s: %(message)s"
)

def _parse_args() -> argparse.Namespace:
    example_text = '''example:
        control-attenuators.py --help'''

    parser = argparse.ArgumentParser(description='Minicicuits Attenuator program: requires root/sudo privileges',
                                    epilog=example_text,
                                    formatter_class=argparse.RawDescriptionHelpFormatter)

    # Get SN / Model / FW version
    parser.add_argument(
        '--info', '-i',
        action='store_true',
        default=False,
        help='Get Infos for all connected Mini-Circuits RC*DAT',
    )

    # Get Attenuation for all
    parser.add_argument(
        '--get-attenuation', '-g',
        action='store_true',
        default=False,
        help='Get Current Attenuation for all connected Mini-Circuits RC*DAT',
    )

    # Set Attenuation for all
    parser.add_argument(
        '--set-attenuation', '-s',
        action='store',
        default=-1.0,
        type=float,
        help='Set Attenuation for all connected Mini-Circuits RC*DAT in dB (value can be in increment of 0.25 dB)',
    )

    # Increment / Decrement Range
    parser.add_argument(
        '--range', '-r',
        action='store',
        default=0.0,
        type=float,
        help='Range in dB from the initial attenuation (can be positive ie increment or negative ie decrement)',
    )

    # Increment / Decrement Delay
    parser.add_argument(
        '--delay', '-d',
        action='store',
        default=0.0,
        type=float,
        help='Time delay for the increment / decrement will be performed in seconds',
    )

    return parser.parse_args()

def _info(devices):
    devIdx = 0
    for dev in devices:
        SerialN=""
        ModelN=""
        Fw=""

        dev.write(1,"*:SN?")
        sn=dev.read(0x81,64)
        i=1
        while (sn[i]<255 and sn[i]>0):
            SerialN=SerialN+chr(sn[i])
            i=i+1

        dev.write(1,"*:MN?")
        mn=dev.read(0x81,64)
        i=1
        while (mn[i]<255 and mn[i]>0):
            ModelN=ModelN+chr(mn[i])
            i=i+1

        dev.write(1,"*:FIRMWARE?")
        sn=dev.read(0x81,64)
        i=1

        while (sn[i]<255 and sn[i]>0):
            Fw=Fw+chr(sn[i])
            i=i+1

        logging.info(f'Attenuator #{devIdx}: model is {ModelN}')
        logging.info(f'Attenuator #{devIdx}: serial number is {SerialN}')
        logging.info(f'Attenuator #{devIdx}: FW version is {Fw}')
        devIdx += 1

def _get_attenuation(devices):
    devIdx = 0
    attValue = -1.0
    for dev in devices:
        dev.write(1,"*:ATT?")
        sn=dev.read(0x81,64)
        i=1
        AttResp=""

        while (sn[i]<255 and sn[i]>0):
            AttResp=AttResp+chr(sn[i])
            i=i+1
        logging.info(f'attenuator #{devIdx} set to {AttResp} dB')
        if devIdx == 0:
            attValue = float(AttResp)
        else:
            if attValue != float(AttResp):
                logging.error(f'attenuator #{devIdx} does NOT have the same value as #0')
                logging.error(f'You may want to set them to the same value')
        devIdx += 1
    return attValue

def _set_attenuation(devices, value):
    for dev in devices:
        dev.write(1,f"*:CHAN:1:SETATT:{value};")
        sn=dev.read(0x81,64)
        i=1
        AttResp=""

        while (sn[i]<255 and sn[i]>0):
            AttResp=AttResp+chr(sn[i])
            i=i+1

def _attenuation_variation(devices, att_range, att_delay):
    curr_att = _get_attenuation(devices)
    final_att = curr_att + att_range

    if final_att < 0:
        logging.error(f'Cannot decrease attenuation from {curr_att} dB to {final_att} dB')
        sys.exit(-1)

    if final_att > 110:
        logging.error(f'Cannot increase attenuation from {curr_att} dB to {final_att} dB')
        sys.exit(-1)

    time_step = att_delay / (4 * abs(att_range))
    if att_range < 0.0:
        logging.info(f'will decrement by 0.25 dB steps each {time_step} seconds')
        sign_of_increment = -1
    else:
        logging.info(f'will increment by 0.25 dB steps each {time_step} seconds')
        sign_of_increment = +1

    attenuation = curr_att 
    attenuation += (0.25 * sign_of_increment)
    while ((att_range > 0.0) and (attenuation <= final_att)) or ((att_range < 0.0) and (attenuation >= final_att)):
        logging.debug(f'next attenuation is {attenuation} dB')
        _set_attenuation(devices, attenuation)
        time.sleep(time_step)
        attenuation += (0.25 * sign_of_increment)

    _get_attenuation(devices)

if __name__ == '__main__':
    # Parse the arguments
    args = _parse_args()

    devs = []
    for dev in usb.core.find(idVendor=0x20ce, idProduct=0x0023, find_all=True):
        for configuration in dev:
            for interface in configuration:
                ifnum = interface.bInterfaceNumber
                if not dev.is_kernel_driver_active(ifnum):
                    continue
                try:
                    dev.detach_kernel_driver(ifnum)
                except e:
                    pass
        devs.append(dev)

    if len(devs) == 0:
        logging.error('no Mini-Circuits RC*DAT device detected')
        sys.exit(-1)

    if args.info:
        _info(devs)
        sys.exit(0)

    if args.get_attenuation:
        _get_attenuation(devs)

    if args.set_attenuation != -1:
        _get_attenuation(devs)
        _set_attenuation(devs, args.set_attenuation)
        new_att = _get_attenuation(devs)
        if new_att != args.set_attenuation:
            logging.error(f'Current Attenuation ({new_att} dB) does NOT match intended value ({args.set_attenuation} dB). Problem?')
            sys.exit(-1)

    if args.range != 0.0 and args.delay != 0.0:
        _attenuation_variation(devs, args.range, args.delay)
