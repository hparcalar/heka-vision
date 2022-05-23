import socket
import binascii
from src.gp7_messages import *

class Gp7Connector:

    def __init__(self, robot_ip, port) -> None:
        self._robotIp = robot_ip
        self._port = port
        self._socket = None
        self._connectionStatus = False

    def __connect(self):
        try:
            if not self._socket:
                self._socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                self._socket.settimeout(1.0)
            if self._connectionStatus == False:
                self._socket.connect((self._robotIp, self._port))
                self._connectionStatus = True
        except Exception as e: 
            self._connectionStatus = False
            # print(e)


    def __disconnect(self):
        try:
            if self._socket:
                self._socket.close()
                self._socket = None
        except:
            pass
        self._connectionStatus = False


    def readInteger(self, addrNo):
        self.__connect()

        data = None
        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            self._socket.settimeout(1.0)
            cmd = readIntMsg.replace('{PRM}', convertedAddr)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
            binData = [ retData[32], retData[33] ]
            data = int.from_bytes(binData, 'little', signed=True)
        except Exception as e:
            # print(e)
            pass

        self.__disconnect()
        return data
        

    def readBit(self, addrNo):
        self.__connect()

        data = None
        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            self._socket.settimeout(1.0)
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

            self._socket.settimeout(1.0)
            cmd = writeIntMsg.replace('{PRM}', convertedAddr).replace('{VAL}', convertedVal)
            
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)

        except Exception as e:
            # print(e)
            pass

        self.__disconnect()


    def writeBit(self, addrNo, byteVal):
        self.__connect()

        try:
            convertedAddr = format(addrNo, 'x')
            if len(convertedAddr) == 1:
                convertedAddr = '0' + convertedAddr

            convertedVal = binascii.hexlify(int.to_bytes(byteVal,2,byteorder='little', signed=True), ' ').decode()

            self._socket.settimeout(1.0)
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
            self._socket.settimeout(1.0)
            cmd = writeRegisterMsg.replace('{PRM}', convertedAddr).replace('{VAL}', convertedVal)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)

        except Exception as e:
            print(e)

        self.__disconnect()


    def setHoldStatus(self, holdOn):
        self.__connect()

        try:
            self._socket.settimeout(1.0)
            cmd = holdOnMsg if holdOn == True else holdOffMsg
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def setServoStatus(self, servoOn):
        self.__connect()

        try:
            self._socket.settimeout(1.0)
            cmd = servoOnMsg if servoOn == True else servoOffMsg
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def selectJob(self, jobName):
        self.__connect()

        try:
            self._socket.settimeout(1.0)
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
            self._socket.settimeout(1.0)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def resetAlarm(self):
        self.__connect()

        try:
            cmd = alarmResetMsg
            self._socket.settimeout(1.0)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def cancelError(self):
        self.__connect()

        try:
            cmd = errorCancelMsg
            self._socket.settimeout(1.0)
            self._socket.sendall(bytearray.fromhex(cmd))
            retData = self._socket.recv(1024)
        except Exception as e:
            print(e)

        self.__disconnect()


    def readStatus(self):
        self.__connect()

        try:
            cmd = statusReadMsg
            self._socket.settimeout(1.0)
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
    

