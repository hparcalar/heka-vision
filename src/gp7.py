from gettext import bind_textdomain_codeset
import socket
import binascii
from bitstring import BitArray
from src.gp7_messages import *

class Gp7Connector:

    def __init__(self, robot_ip, port) -> None:
        self._robotIp = robot_ip
        self._port = port
        self._socket = None


    def __connect(self):
        try:
            self._socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self._socket.connect((self._robotIp, self._port))
        except Exception as e: 
            print(e)


    def __disconnect(self):
        try:
            if self._socket:
                self._socket.close()
        except:
            pass


    def readInteger(self, addrNo):
        self.__connect()

        data = None
        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            cmd = readIntMsg.replace('{PRM}', convertedAddr)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
            binData = [ retData[32], retData[33] ]
            data = int.from_bytes(binData, 'little', signed=True)
        except Exception as e:
            print(e)

        self.__disconnect()
        return data
        

    def readBit(self, addrNo):
        self.__connect()

        data = None
        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            cmd = readByteMsg.replace('{PRM}', convertedAddr)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
            binData = [ retData[32] ]
            data = int.from_bytes(binData, 'little', signed=True)
        except Exception as e:
            print(e)

        self.__disconnect()
        return data
        
    
    def writeInteger(self, addrNo, intVal):
        self.__connect()

        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            convertedVal = binascii.hexlify(int.to_bytes(intVal,2,byteorder='little', signed=True), ' ').decode()

            cmd = writeIntMsg.replace('{PRM}', convertedAddr).replace('{VAL}', convertedVal)
            
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)

        except Exception as e:
            print(e)

        self.__disconnect()


    def writeBit(self, addrNo, byteVal):
        self.__connect()

        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            convertedVal = binascii.hexlify(int.to_bytes(byteVal,2,byteorder='little', signed=True), ' ').decode()

            cmd = writeBitMsg.replace('{PRM}', convertedAddr).replace('{VAL}', convertedVal)
            
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)

        except Exception as e:
            print(e)

        self.__disconnect()


    def writeRegister(self, addrNo, intVal):
        self.__connect()

        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            convertedVal = binascii.hexlify(int.to_bytes(intVal,2,byteorder='little', signed=True), ' ').decode()
            cmd = writeRegisterMsg.replace('{PRM}', convertedAddr).replace('{VAL}', convertedVal)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)

        except Exception as e:
            print(e)

        self.__disconnect()


    def setHoldStatus(self, holdOn):
        self.__connect()

        try:
            cmd = holdOnMsg if holdOn == True else holdOffMsg
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def setServoStatus(self, servoOn):
        self.__connect()

        try:
            cmd = servoOnMsg if servoOn == True else servoOffMsg
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def selectJob(self, jobName):
        self.__connect()

        try:
            encodedJobName = bytearray(jobName, 'ascii')
            if len(encodedJobName) < 32:
                remainingCount = 32 - len(encodedJobName)
                while remainingCount > 0:
                    encodedJobName.append(0)
                    remainingCount = remainingCount - 1

            cmd = selectJobMsg.replace('{PRM}', binascii.hexlify(encodedJobName, ' ').decode())

            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)

        except Exception as e:
            print(e)

        self.__disconnect()
    

    def startJob(self):
        self.__connect()

        try:
            cmd = startJobMsg
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def resetAlarm(self):
        self.__connect()

        try:
            cmd = alarmResetMsg
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def __bin(a):
        s=''
        t={'0':'000','1':'001','2':'010','3':'011',
            '4':'100','5':'101','6':'110','7':'111'}
        for c in oct(a)[1:]:
                s+=t[c]
        return s


    def cancelError(self):
        self.__connect()

        try:
            cmd = errorCancelMsg
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()

    def readStatus(self):
        self.__connect()

        try:
            cmd = statusReadMsg

            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
            print(len(retData))
            print(retData)
            
            print(bin(retData[31]))
            print(bin(retData[32]))
            print(bin(retData[33]))
            print(bin(retData[34]))
            print(bin(retData[35]))
            print(bin(retData[36]))
            print(bin(retData[37]))
            print(bin(retData[38]))

            data1 = retData[32]
            data2 = retData[36]

            print(data2 & 64 != 0) # servo     
            print(data2 & 2 != 0) # hold button
            print(data2 & 16 != 0) # alarm status
            print(data1 & 32 != 0) # teach
            print(data1 & 64 != 0) # play
            print(data1 & 16 != 0) # remote

        except Exception as e:
            print(e)

        self.__disconnect()
    

