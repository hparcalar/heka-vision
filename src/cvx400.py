from cpppo.server.enip.get_attribute import attribute_operations, proxy_simple
from time import sleep

class Cvx400:

    def __init__(self, host_ip) -> None:
        self._hostIp = host_ip
        self._proxy = None

    
    def connect(self):
        try:
            if not self._proxy:
                self._proxy = proxy_simple(self._hostIp)
        except Exception as e:
            print(e)


    def disconnect(self):
        try:
            if self._proxy:
                self._proxy.close_gateway()
        except Exception as e:
            print(e)
        self._proxy = None


    def isAlive(self) -> bool:
        result = False
        if self._proxy:
            try:
                self._proxy.read([('@1/1/7','SSTRING')])
                result = True
            except Exception as e:
                print(e)
        
        return result


    def selectProgram(self, sdCardNo, programNo) -> bool:
        fRes = False
        try:
            result, = self._proxy.read([('@0x6A/0x01/0x74=(UINT)'+ str(sdCardNo) +','+ str(programNo) +'','@0x6A/0x01/0x74')],0)
            resCmd, = self._proxy.read([('@0x6A/0x01/0x76', 'UINT')])
            while resCmd[0] != 0:
                resCmd, = self._proxy.read([('@0x6A/0x01/0x76', 'UINT')])
                if resCmd[0] == 1:
                    break
                sleep(0.5)

            if resCmd[0] == 1:
                print('Failed to load program. Device is not ready')
                fRes = False
            elif resCmd[0] == 0:
                sleep(1.5)
                fRes = True
        except Exception as e:
            print(e)
            fRes = False

        return fRes


    def triggerCamera(self) -> bool:
        fRes = False
        try:
            result, = self._proxy.read([('@0x6A/0x01/0x69=(SINT)0','@0x6A/0x01/0x69')],0)
            result, = self._proxy.read([('@0x6A/0x01/0x69=(SINT)1','@0x6A/0x01/0x69')],0)
            fRes = True
        except Exception as e:
            print(e)
            fRes = False
        
        return fRes


    def disableTrigger(self) -> bool:
        fRes = False
        try:
            result, = self._proxy.read([('@0x6A/0x01/0x69=(SINT)0','@0x6A/0x01/0x69')],0)
            fRes = True
        except Exception as e:
            print(e)
            fRes = False
        return fRes


    def readOutput(self):
        fRes = []
        try:
            fRes, = self._proxy.read([('@0x04/0x64/0x03', 'SINT')])
        except Exception as e:
            print(e)
        return fRes