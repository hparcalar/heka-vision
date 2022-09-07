from cpppo.server.enip.get_attribute import attribute_operations, proxy_simple
from time import sleep
import socket

class Cvx400:

    def __init__(self, host_ip, host_port) -> None:
        self._hostIp = host_ip
        self._hostPort = host_port
        self._busyByCommand = False
        self._proxy = None

    
    def __connect(self):
        try:
            if not self._proxy:
                self._proxy = proxy_simple(self._hostIp)
                #self._proxy.timeout = 5
        except Exception as e:
            pass


    def __disconnect(self):
        try:
            if self._proxy:
                self._proxy.close_gateway()
        except Exception as e:
            pass
        self._proxy = None


    def __waitForAvailable(self):
        while self._busyByCommand == True:
            sleep(0.05)


    def isAlive(self) -> bool:
        self.__waitForAvailable()

        self._busyByCommand = True
        self.__connect()

        result = False
        if self._proxy:
            try:
                res, = self._proxy.read([('@1/1/7','SSTRING')])
                if res:
                    result = True
            except Exception as e:
                result = False

        self.__disconnect()
        self._busyByCommand = False
        
        return result

    
    def switchToRunMode(self):
        fRes = False

        try:
            sck = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sck.settimeout(5.0)
            sck.connect((self._hostIp, self._hostPort))
            sck.send(bytearray('R0\r', 'ascii'))
            resp = sck.recv(1024)
            if resp.decode().find("ER,") == -1:
                fRes = True
            sck.close()
        except Exception as e:
            fRes = False

        return fRes


    def requestScreenshot(self):
        fRes = False

        try:
            sck = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sck.settimeout(5.0)
            sck.connect((self._hostIp, self._hostPort))
            sck.send(bytearray('BC,FTP\r', 'ascii'))
            resp = sck.recv(1024)
            if resp.decode().find("ER,") == -1:
                fRes = True
            sck.close()
        except:
            fRes = False
        
        return fRes


    def selectProgram(self, sdCardNo, programNo) -> bool:
        fRes = False
        try:
            sck = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sck.settimeout(9.0)
            sck.connect((self._hostIp, self._hostPort))
            sck.send(bytearray('PR\r', 'ascii'))
            resp = sck.recv(1024)
            if int(resp.decode().split(',')[2]) != int(programNo):
                sck.send(bytearray('PW,'+ str(sdCardNo) +','+ str(programNo) +'\r', 'ascii'))
                resp = sck.recv(1024)
                if resp.decode().find("ER,") == -1:
                    fRes = True
            else:
                fRes = True
            sck.close()
        except Exception as e:
            # print(e)
            fRes = False

        return fRes


    def setGlobalVars(self, varList) -> bool:
        try:
            sck = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sck.settimeout(9.0)
            sck.connect((self._hostIp, self._hostPort))

            for vr in varList:
                try:
                    if vr['variableName'] >= '$G0013':
                        if int(vr['variableValue']) <= 70 and int(vr['variableValue']) > 50:
                            vr['variableValue'] = 65
                        elif int(vr['variableValue']) <= 50 and int(vr['variableValue']) > 30:
                            vr['variableValue'] = 48
                        elif int(vr['variableValue']) <= 30 and int(vr['variableValue']) > 10:
                            vr['variableValue'] = 30
                        else:
                            vr['variableValue'] = 15

                        # OLD element size calculation
                        # if int(vr['variableValue']) <= 70 and int(vr['variableValue']) > 50:
                        #     vr['variableValue'] = 36
                        # elif int(vr['variableValue']) <= 50 and int(vr['variableValue']) > 30:
                        #     vr['variableValue'] = 16
                        # elif int(vr['variableValue']) <= 30 and int(vr['variableValue']) > 10:
                        #     vr['variableValue'] = 8
                        # else:
                        #     vr['variableValue'] = 4
                            
                    sck.send(bytearray('MW,'+ vr['variableName'] +','+ str(vr['variableValue']) +'\r', 'ascii'))
                    vrChangeResult = sck.recv(1024)
                except:
                    pass
                
            sck.close()
            pass
        except:
            pass

        return False


    def triggerCamera(self) -> bool:
        self.__waitForAvailable()

        self._busyByCommand = True
        self.__connect()

        fRes = False
        try:
            result, = self._proxy.read([('@0x68/0x01/0x69=(SINT)0','@0x68/0x01/0x69')],0)
            result, = self._proxy.read([('@0x68/0x01/0x69=(SINT)1','@0x68/0x01/0x69')],0)
            fRes = True
        except Exception as e:
            # print(e)
            fRes = False
        
        self.__disconnect()
        self._busyByCommand = False

        return fRes


    # OBSOLOTE
    def disableTrigger(self) -> bool:
        fRes = False
        try:
            result, = self._proxy.read([('@0x68/0x01/0x69=(SINT)0','@0x68/0x01/0x69')],0)
            fRes = True
        except Exception as e:
            # print(e)
            fRes = False
        return fRes


    def isOutputReady(self) -> bool:
        self.__waitForAvailable()

        self._busyByCommand = True
        self.__connect()

        fRes = False
        try:
            result, = self._proxy.read([('@0x68/0x01/0x6A', 'SINT')])
            # print(str((result[0] & 128) != 0) + ',' + str((result[0] & 64) != 0) + ',' + str((result[0] & 32) != 0) + ',' +str((result[0] & 16) != 0) + ',' + str((result[0] & 8) != 0) + ',' + str((result[0] & 4) != 0) + ',' + str((result[0] & 2) != 0) + ',' + str((result[0] & 1) != 0))
            fRes = result and (result[0] & 1) != 0
        except:
            fRes = False

        self.__disconnect()
        self._busyByCommand = False

        return fRes


    def readOutput(self):
        self.__waitForAvailable()

        self._busyByCommand = True
        self.__connect()

        fRes = []
        try:
            fRes, = self._proxy.read([('@0x04/0x64/0x03', 'USINT')]) # cvx 064, xgx 065
        except Exception as e:
            pass
            # print(e)

        self.__disconnect()
        self._busyByCommand = False

        return fRes