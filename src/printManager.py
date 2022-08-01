import usb
from datetime import datetime

class PrintManager:
    def __init__(self) -> None:
        self.__ep = None
        self.__tryConnectToPrinter()

    def __tryConnectToPrinter(self):
        if not self.__ep == None:
            return

        try:
            dev = usb.core.find(idVendor=0x1664, idProduct=0x019a)
            # dev.set_configuration()

            # get an endpoint instance
            cfg = dev.get_active_configuration()
            intf = cfg[(0,0)]

            self.__ep = usb.util.find_descriptor(
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
        except:
            pass
        pass


    def printLabel(self, data:dict) -> bool:
        self.__tryConnectToPrinter()
        
        result = False
        try:
            dateStr = datetime.now().strftime('%d.%m.%Y %H:%M')

            # write the data
            # new label 3,5 x 1,5 cm
            self.__ep.write(chr(0x02) + 'f320\r')
            self.__ep.write(chr(0x02) + 'L\r')
            self.__ep.write('101100000450015'+ str(data['employeeName']) +'\r')
            # ep.write('121100000350125'+ ('OK' if data['result'] == True else 'NOK') +'\r')
            self.__ep.write('101100000350015'+ dateStr +'\r')
            self.__ep.write('101100000250015'+ str(data['shiftCode']) +' VARDIYASI\r')
            self.__ep.write('1W1c33000000500902000000000'+ str(data['barcode']) +'\r')
            self.__ep.write('E\r')
            self.__ep.write(chr(0x02) + ' F\r')

            # old label 4 x 2 cm
            # self.__ep.write(chr(0x02) + 'f320\r')
            # self.__ep.write(chr(0x02) + 'L\r')
            # self.__ep.write('101100000600015'+ str(data['employeeName']) +'\r')
            # # self.__ep.write('121100000500125'+ ('OK' if data['result'] == True else 'NOK') +'\r')
            # self.__ep.write('101100000500015'+ dateStr +'\r')
            # self.__ep.write('101100000400015'+ str(data['shiftCode']) +' VARDIYASI\r')
            # self.__ep.write('1W1c44000000500702000000000'+ str(data['barcode']) +'\r')
            # self.__ep.write('E\r')
            # self.__ep.write(chr(0x02) + ' F\r')

            result = True
        except Exception as e:
            # print(e)
            result = False

        return result