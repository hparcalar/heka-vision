import usb
from datetime import datetime


def printLabel(data:dict) -> bool:
    result = False
    try:
        dev = usb.core.find(idVendor=0x1664, idProduct=0x019a)
        # dev.set_configuration()

        # get an endpoint instance
        cfg = dev.get_active_configuration()
        intf = cfg[(0,0)]

        ep = usb.util.find_descriptor(
            intf,
            custom_match = \
            lambda e: \
                usb.util.endpoint_direction(e.bEndpointAddress) == \
                usb.util.ENDPOINT_OUT)

        if dev.is_kernel_driver_active(0):
            try:
                dev.detach_kernel_driver(0)
            except usb.core.USBError as e:
                pass

        try:
            usb.util.claim_interface(dev, 0)
        except:
            pass

        dateStr = datetime.now().strftime('%d.%m.%Y %H:%M')

        # write the data
        ep.write(chr(0x02) + 'f320\r')
        ep.write(chr(0x02) + 'L\r')
        ep.write('101100000600015'+ str(data['employeeName']) +'\r')
        ep.write('121100000500125'+ ('OK' if data['result'] == True else 'NOK') +'\r')
        ep.write('101100000500015'+ dateStr +'\r')
        ep.write('101100000400015'+ str(data['shiftCode']) +' VARDIYASI\r')
        ep.write('1E3101700050015'+ str(data['barcode']) +'\r')
        ep.write('E\r')
        ep.write(chr(0x02) + ' F\r')

        result = True
    except:
        result = False

    return result