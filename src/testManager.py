from src.cvx400 import *
from src.gp7 import *
from src.hkThread import HekaThread
from datetime import datetime


class TestManager:

    def __init__(self, backend) -> None:
        self._backend = backend
        self._product = None
        self._comConfig = None
        self._robot = None
        self._camera = None
        self._updateMaterials = False
        self._activeStepIndex = 0
        self._stepStatus = False
        self._isTestRunning = False

        self._nextStepIsArrivedHome = False
        self._nextStepArrivingIsWaiting = False

        self._barrierThread = None
        self._lightBarrierOk = False
        self._barrierThreadRun = False

        self._hatchCheckThread = None
        self._hatchIsClosed = False
        self._closeHatchCommandActivated = False


    def __moveNextStep(self):
        self._activeStepIndex = self._activeStepIndex + 1
        try:
            if len(self._product['steps']) <= self._activeStepIndex:
                self._isTestRunning = False
                self._barrierThreadRun = False
                self._stepStatus = False
                self._activeStepIndex = 0

                self._robot.writeInteger(0, 0)
                self._robot.writeBit(3, 1)

                try:
                    self.__stopHatchCheckThread()
                    self.openHatch()
                    self.__moveRobotToHome()
                    # self._robot.writeBit(3,0)
                    self.__stopBarrierThread()
                    self._backend.raiseAllStepsFinished()
                except Exception as e:
                    pass

        except:
            pass

    def __raiseError(self, msg):
        self.stopTest()
        if self._backend:
            self._backend.raiseStepError(msg)

    def __raiseStartPosArrived(self):
        self._backend.raiseStartPosArrived()

    def __raiseStepResult(self, result, msg):
        if self._backend:
            self._backend.raiseStepResult(result, msg)

    def __createMaterials(self):
        if self._comConfig and self._updateMaterials == True:
            try:
                self._robot = Gp7Connector(self._comConfig['robotIp'], self._comConfig['robotPort'])
                self._camera = Cvx400(self._comConfig['cameraIp'], int(self._comConfig['cameraPort']))
                self._updateMaterials = False
            except Exception as e:
                pass


    def __checkAliveStatus(self) -> bool:
        return self.checkRobotIsAlive() and self.checkCameraIsAlive()

    def __writeToRobot(self, typeAndAddr, data) -> bool:
        result = False
        try:
            if typeAndAddr[0] == 'INT':
                self._robot.writeInteger(int(typeAndAddr[1]), data)
            elif typeAndAddr[0] == 'BIT':
                self._robot.writeBit(int(typeAndAddr[1]), data)
            elif typeAndAddr[0] == 'REG':
                self._robot.writeRegister(int(typeAndAddr[1]), int(data))
            result = True
        except:
            result = False
        return result


    def __readFromRobot(self, typeAndAddr):
        result = None
        try:
            if typeAndAddr[0] == 'INT':
                result = self._robot.readInteger(int(typeAndAddr[1]))
            elif typeAndAddr[0] == 'BIT':
                result = self._robot.readBit(int(typeAndAddr[1]))
        except:
            result = None

        return result

    def __moveRobotToHome(self) -> bool:
        try:
            # GOTO SAFETY HOME

            # HOME ADIMININ VARIŞINDA BYTE 1=1 OLMASI GEREKTİĞİ İÇİN SIFIRLANIYOR
            self._robot.writeBit(1, 0)
            safetyHomeData = self._comConfig['rbToSafetyHome'].split(':')
            self.__writeToRobot(safetyHomeData, int(safetyHomeData[2]))
            sleep(0.2)
            self._robot.writeBit(3, 0)

            # WAIT UNTIL ROBOT ARRIVES AT SAFETY HOME
            tryCount = 0
            arriveHomeData = self._comConfig['rbFromSafetyHome'].split(':')
            isHome = self.__readFromRobot(arriveHomeData)
            while not isHome or int(isHome) != int(arriveHomeData[2]):
                isHome = self.__readFromRobot(arriveHomeData)
                if self._isTestRunning == False:
                    return
                # print('HOME VARIŞ: ' + str(isHome))
                sleep(0.1)
                tryCount = tryCount + 1
                if tryCount > 300: # max timeout 10 sn
                    # self.__raiseError('Robot Başlangıç Pozisyonuna Getirilemedi.')
                    if self._isTestRunning == False:
                        return False

                    self._robot.writeInteger(0,0)
                    self._robot.writeBit(3, 1)
                    self._robot.writeBit(4,1)
                    return False


            self._robot.writeInteger(0,0)
            sleep(0.1)
            self._robot.writeBit(3, 1)

            self.__raiseStartPosArrived()

            return True
        except:
            return False

    def __prepareRobotToStart(self) -> bool:
        result = False
        try:
            # RESET ALARM
            self._robot.resetAlarm()
            self._robot.setHoldStatus(False)
            self._backend.raiseResetOk()
            self._camera.switchToRunMode()
            sleep(0.001)

            # self._robot.writeBit(1, 0)
            self._robot.selectJob(self._comConfig['rbToMasterJob'])
            self._backend.raiseMasterJobOk()
            sleep(0.001)

            self._robot.setServoStatus(True)
            self._backend.raiseServoOnOk()
            sleep(0.001)

            self._robot.startJob()
            self._backend.raiseStartOk()

            self._robot.writeInteger(0, 0)
            self._robot.writeBit(3, 1)

            moveHomeResult = self.__moveRobotToHome()
            if moveHomeResult == False:
                return moveHomeResult

            result = True
        except Exception as e:
            result = False
            # print(e)

        return result

    def __productSensorIsFull(self) -> bool:
        if not self._robot:
            return False

        retData = self._robot.readExternalIo(2, 1)
        
        return (not retData == None) and retData != 0


    def __checkLightBarrier(self) -> bool:
        if not self._robot:
            return False

        retData = self._robot.readBarrier(2, 16)
        if not retData == None:
            lightIsOk = retData != 0
            return lightIsOk

        return False
    
    
    def __startBarrierThread(self):
        try:
            if self._barrierThread == None:
                self._barrierThread = HekaThread(target=self.__loopBarrierThread)
            else:
                try:
                    self._barrierThread.stop()
                    self._barrierThread = None
                except:
                    pass
                self._barrierThread = HekaThread(target=self.__loopBarrierThread)
            
            self._barrierThread.start()
        except Exception as e:
            pass


    def __stopBarrierThread(self):
        try:
            if not self._barrierThread == None:
                self._barrierThread.stop()
                self._barrierThread = None
        except:
            pass


    def __loopBarrierThread(self):
        #pass
        while self._isTestRunning == True or self._barrierThreadRun == True:
            try:
                self._lightBarrierOk = self.__checkLightBarrier()
                if self._lightBarrierOk == False:
                    self.__raiseError('Müdahale tespit edildi. Test durduruldu.')
                    self.setRobotHold(True)
                    self._barrierThreadRun = False
                    break
                sleep(0.05)
            except:
                pass
        

    def __startHatchCheckThread(self):
        try:
            if self._hatchCheckThread == None:
                self._hatchCheckThread = HekaThread(target=self.__loopHatchCheckThread)
            else:
                try:
                    self._hatchCheckThread.stop()
                    self._hatchCheckThread = None
                except:
                    pass
                self._hatchCheckThread = HekaThread(target=self.__loopHatchCheckThread)
            
            self._hatchCheckThread.start()
        except Exception as e:
            pass


    def __stopHatchCheckThread(self):
        try:
            if not self._hatchCheckThread == None:
                self._hatchCheckThread.stop()
                self._hatchCheckThread = None
        except:
            pass


    def __loopHatchCheckThread(self):
        dtCmdStart = None
        while self._closeHatchCommandActivated == True: # or self._isTestRunning == True:
            try:
                self._hatchIsClosed = self.checkHatchIsClosed()
                if self._hatchIsClosed == False and self._closeHatchCommandActivated == False:
                    self.setRobotHold(True)
                    self.__raiseError('Kapak kapalı değil. Test durduruldu.')
                    break
                elif self._closeHatchCommandActivated == True:
                    if self._hatchIsClosed == False:
                        if dtCmdStart == None:
                            dtCmdStart = datetime.now()
                        
                        dtCheck = datetime.now()

                        diffInSec = (dtCheck - dtCmdStart).seconds
                        if diffInSec >= 5:
                            testRunning = self._isTestRunning
                            self._closeHatchCommandActivated = False
                            self.stopClosingHatch()
                            self.setRobotHold(True)

                            if testRunning == True:
                                self.__raiseError('Kapak kapalı değil. Test durduruldu.')

                            break
                    else:
                        self._closeHatchCommandActivated = False
            except:
                pass
            sleep(0.2)
    

    def __waitForStartPosArrived(self, readyToStartData):
        self._nextStepArrivingIsWaiting = True
        self._nextStepIsArrivedHome = False

        sleep(0.2)

        tryCount = 0
        arrivePosData = readyToStartData.split(':')
        onPos = self.__readFromRobot(arrivePosData)
        while not onPos or int(onPos) != int(arrivePosData[2]):
            if self._isTestRunning == False:
                return

            onPos = self.__readFromRobot(arrivePosData)
            sleep(0.1)
            tryCount = tryCount + 1
            if tryCount > 300: # max timeout 10 sn
                self._robot.writeInteger(0,0)
                self._robot.writeBit(3, 1)
                if self._isTestRunning == True:
                    self.__raiseError('Robot Beklenen Pozisyona Getirilemedi.')
                    self._nextStepArrivingIsWaiting = False
                return

        self._nextStepIsArrivedHome = True
        self._nextStepArrivingIsWaiting = False


    def stopTest(self):
        self._stepStatus = False
        self._isTestRunning = False
        self._barrierThreadRun = False
        sleep(1)
        self._activeStepIndex = 0
        self.__stopBarrierThread()
        self.__stopHatchCheckThread()

    
    def checkProductSensor(self) -> bool:
        # if self._isTestRunning == True:
        #     return True
        return self.__productSensorIsFull()


    def checkRobotIsAlive(self) -> bool:
        # return True
        if self._isTestRunning:
            return True

        result = False
        try:
            if self._robot and not self._robot.readInteger(0) == None:
                result = True
        except Exception as e:
            result = False

        return result


    def checkCameraIsAlive(self) -> bool:
        # return True
        if self._isTestRunning:
            return True

        result = False

        try:
            if self._camera:
                result = self._camera.isAlive()
        except:
            result = False

        return result

    
    def initDevices(self, comConfig):
        if not self._comConfig or self._comConfig['robotIp'] != comConfig['robotIp'] or self._comConfig['robotPort'] != comConfig['robotPort'] or self._comConfig['cameraIp'] != comConfig['cameraIp']:
            self._updateMaterials = True
            self._comConfig = comConfig
            self.__createMaterials()


    def startTest(self, productData):
        if self.__checkAliveStatus():
            # check robot status
            robotStats = self.readRobotStatus()
            if not robotStats == None:
                if robotStats['Teach'] == True:
                    self.__raiseError('Başlatmak için robotu manuel modundan çıkartınız.')
                    return
            

            self._isTestRunning = True
            # self._hatchIsClosed = False
            self._product = productData
            self._activeStepIndex = 0

            self.__startBarrierThread()
            sleep(0.05)

            # start close hatch control
            self.setVacuum(1)
            self.closeHatch()

            # sleep(0.1) disabled below
            # while self._hatchIsClosed == False:
            #     if self._isTestRunning == False:
            #         return
            #     sleep(0.1)
            
            if not self.__prepareRobotToStart():
                if self._isTestRunning == False:
                    self.__raiseError('Robot Başlatılamadı')
                return

            self.startCurrentStep()
        else:
            self.stopTest()
            self.__raiseError('Robot ve Kamera İletişimini Kontrol Edin')
  

    def setRobotHold(self, status):
        self._robot.setHoldStatus(status)

        if status == True:
            # self.openHatch()
            self.stopClosingHatch()
            self.stopTest()


    def checkHatchIsClosed(self):
        retData = self._robot.readExternalIo(2, 4)
        return (not retData == None) and retData != 0


    def openHatch(self) -> bool:
        self._lightBarrierOk = self.__checkLightBarrier()

        if self._lightBarrierOk == True:
            self._robot.writeExternalIo(2702, 0) # disable down signal
            sleep(0.1)
            self.setVacuum(0)
            sleep(0.2)
            self._robot.writeExternalIo(2701, 1) # enable up signal

            tryCount = 0
            while self.checkHatchIsClosed():
                sleep(0.2)
                tryCount = tryCount + 1

                if tryCount >= 25:
                    self.__raiseError('Kapak açılamadı, havayı kontrol ediniz.')
                    self.stopTest()
                    return False

            return True

    
    def closeHatch(self, manuelClose = False) -> bool:
        if manuelClose == False:
            self._closeHatchCommandActivated = True
            self.__startHatchCheckThread()

            self._barrierThreadRun = True
            self.__startBarrierThread()

        self._lightBarrierOk = self.__checkLightBarrier()

        if self._lightBarrierOk == True:
            self._robot.writeExternalIo(2701, 0) # disable up signal
            sleep(0.1)
            return self._robot.writeExternalIo(2702, 1) # enable down signal
        else:
            return False


    def stopClosingHatch(self) -> bool:
        self._robot.writeExternalIo(2702, 0)
        self.setVacuum(0)
        return True


    def readRobotStatus(self):
        try:
            return self._robot.readStatus()
        except:
            return None
        

    def setVacuum(self, status: int) -> bool:
        #pass
        self._robot.writeExternalIo(2703, status)


    def startCurrentStep(self):
        try:
            if self._isTestRunning == False:
                return

            if not len(self._product['steps']) > self._activeStepIndex:
                return

            activeStep = self._product['steps'][self._activeStepIndex]
            if activeStep and activeStep['camRecipe']:
                self._stepStatus = True
                recipe = activeStep['camRecipe']
                
                if not recipe['recipeCode']:
                    self.__raiseError('Reçete No Bilgisi Girilmemiş')
                    return

                
                if self._stepStatus == False:
                    return

                # SELECT RECIPE FROM CAMERA
                recipeNoData = recipe['recipeCode'].split(':')
                camRes = self._camera.selectProgram(recipeNoData[0], recipeNoData[1])
                if not camRes:
                    if self._isTestRunning == True:
                        self.__raiseError('Reçete Programı Seçilemedi')
                    return

                if self._stepStatus == False:
                    return

                # RESET ROBOT MOVEMENT FOR CAMERA TRIGGER
                rbToStartScanningData = recipe['rbToStartScanning'].split(':')
                self.__writeToRobot(rbToStartScanningData, 0)


                # SEND ROBOT GOTO START POSITION OF CURRENT STEP
                rbGotoPositionData = recipe['rbToRecipeStarted'].split(':')
                if self._activeStepIndex == 0:
                    rbGotoPositionData = recipe['rbToRecipeStarted'].split(':')
                    self._robot.writeBit(0,0)
                    self.__writeToRobot(rbGotoPositionData, int(rbGotoPositionData[2]))

                if self._stepStatus == False:
                    return

                # WAIT UNTIL ROBOT ARRIVES AT POSITION OF CURRENT STEP
                if self._activeStepIndex == 0:
                    tryCount = 0
                    arrivePosData = recipe['rbFromReadyToStart'].split(':')
                    onPos = self.__readFromRobot(arrivePosData)
                    while not onPos or int(onPos) != int(arrivePosData[2]):
                        if self._isTestRunning == False:
                            return

                        onPos = self.__readFromRobot(arrivePosData)
                        sleep(0.1)
                        tryCount = tryCount + 1
                        if tryCount > 300: # max timeout 10 sn
                            self._robot.writeInteger(0,0)
                            self._robot.writeBit(3, 1)
                            if self._isTestRunning == True:
                                self.__raiseError('Robot Beklenen Pozisyona Getirilemedi.')
                            return
                else:
                    while self._nextStepIsArrivedHome == False:
                        if self._stepStatus == False:
                            return
                        sleep(0.1)

                self.__raiseStartPosArrived()


                # ENABLE CAMERA TRIGGER
                trgResult = self._camera.triggerCamera()
                if not trgResult:
                    self.__raiseError('Kamerayı Otomatik(Run) Moda Alınız')
                    return

                if self._stepStatus == False:
                    return

                # APPLY RECIPE START DELAY
                if recipe['startDelay'] and int(recipe['startDelay'] > 0):
                    sleep(recipe['startDelay'] / 1000.0)

                if self._stepStatus == False:
                    return

                # SEND ROBOT START TO SCAN
                self.__writeToRobot(rbToStartScanningData, int(rbToStartScanningData[2]))
                self._robot.writeBit(3, 0)

                if self._stepStatus == False:
                    return

                # WAIT UNTIL ROBOT SCAN MOVEMENT IS FINISHED
                tryCount = 0
                scanEndPosData = recipe['rbFromScanningFinished'].split(':')
                onPos = self.__readFromRobot(scanEndPosData)
                while not onPos or int(onPos) != int(scanEndPosData[2]):
                    if self._stepStatus == False:
                        return

                    if self._isTestRunning == False:
                        return

                    onPos = self.__readFromRobot(scanEndPosData)
                    sleep(0.1)
                    tryCount = tryCount + 1
                    if tryCount > 300: # max timeout 10 sn
                        if self._isTestRunning == True:
                            self.__raiseError('Robot Bölge Taramasını Tamamlayamadı')
                        return

                # SEND ROBOT GOTO START POSITION OF NEXT STEP
                self._nextStepIsArrivedHome = False
                if self._activeStepIndex + 1 < len(self._product['steps']):
                    # while self._nextStepArrivingIsWaiting == True:
                    #     sleep(0.1)

                    self._robot.writeInteger(0, 0)
                    self._robot.writeBit(3, 1)

                    nextStep = self._product['steps'][self._activeStepIndex + 1]
                    nextRecipe = nextStep['camRecipe']

                    # DISABLE SCAN TRIGGER OF NEXT STEP
                    rbToStartScanningDataNext = nextRecipe['rbToStartScanning'].split(':')
                    self.__writeToRobot(rbToStartScanningDataNext, 0)

                    rbGotoPositionDataNext = nextRecipe['rbToRecipeStarted'].split(':')
                    
                    self._robot.writeBit(0,0)
                    self.__writeToRobot(rbGotoPositionDataNext, int(rbGotoPositionDataNext[2]))
                    posArrivedThr = HekaThread(target=self.__waitForStartPosArrived, args=[nextRecipe['rbFromReadyToStart']])
                    posArrivedThr.start()


                # UPDATE! = WAIT UNTIL CAMERA OUTPUT IS READY
                tryCount = 0
                isOutputReady = self._camera.isOutputReady()
                while isOutputReady == False:
                    # print('KAMERA BEKLENİYOR')
                    if self._stepStatus == False:
                        return

                    if self._isTestRunning == False:
                        return

                    isOutputReady = self._camera.isOutputReady()
                    sleep(0.1)

                    tryCount = tryCount + 1
                    if tryCount > 100:
                        if self._isTestRunning == True:
                            self.__raiseError('Kamera Output Bilgisi Alınamadı')
                        return

                if self._stepStatus == False:
                    return

                # READ INSPECTION RESULTS
                testResult = False
                camResult = self._camera.readOutput()

                try:
                    resultFormat = recipe['camResultFormat'].split(':')
                    if camResult and len(camResult) > int(resultFormat[0]):
                        bIndex = 0
                        testResult = True
                        while bIndex < int(resultFormat[1]):
                            # print('BINDEX')
                            testResult = camResult[int(resultFormat[0]) + int(bIndex * 4)] == 0
                            
                            if testResult == False:
                                break
                            bIndex = bIndex + 1
                except Exception:
                    pass

                self.__raiseStepResult(testResult, str(activeStep['id']))
                
                sleep(1) # wait for capture image store to ftp
                # sleep(7)  

                if self._stepStatus == False:
                    self.stopTest()
                    return

                if testResult:
                    self.__moveNextStep()
                    self.startCurrentStep()
                else:
                    self.__moveNextStep()
                    self.startCurrentStep()
                    # self.stopTest()
                    # self._backend.raiseAllStepsFinished()
            else:
                self.__raiseError('Test Adımı İçin Reçete Bilgisi Girilmemiş')
                self.stopTest()
        except Exception as e:
            self.__raiseError(str(e))
            self.stopTest()


    