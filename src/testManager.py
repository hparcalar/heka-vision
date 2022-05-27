from src.cvx400 import *
from src.gp7 import *
from src.hkThread import HekaThread

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


    def __moveNextStep(self):
        self._activeStepIndex = self._activeStepIndex + 1
        try:
            if len(self._product['steps']) <= self._activeStepIndex:
                # try:
                #     safetyHomeData = self._comConfig['rbToSafetyHome'].split(':')
                #     self.__writeToRobot(safetyHomeData, int(safetyHomeData[2]))
                # except:
                #     pass
                self.__moveRobotToHome()
                self._robot.writeBit(3,0)
                self._backend.raiseAllStepsFinished()
                self._isTestRunning = False
                self._stepStatus = False
                self._activeStepIndex = 0
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
                print(e)


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
            self._robot.writeBit(3, 0)

            # WAIT UNTIL ROBOT ARRIVES AT SAFETY HOME
            tryCount = 0
            arriveHomeData = self._comConfig['rbFromSafetyHome'].split(':')
            isHome = self.__readFromRobot(arriveHomeData)
            while not isHome or int(isHome) != int(arriveHomeData[2]):
                isHome = self.__readFromRobot(arriveHomeData)
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
            sleep(0.2)

            # self._robot.writeBit(1, 0)
            self._robot.selectJob(self._comConfig['rbToMasterJob'])
            self._backend.raiseMasterJobOk()
            sleep(0.2)

            self._robot.setServoStatus(True)
            self._backend.raiseServoOnOk()
            sleep(0.2)

            self._robot.startJob()
            self._backend.raiseStartOk()

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
        
        return self._robot.readExternalIo(3) == 1

    def stopTest(self):
        self._stepStatus = False
        self._isTestRunning = False
        sleep(1)
        self._activeStepIndex = 0

    
    def checkProductSensor(self) -> bool:
        if self._isTestRunning == True:
            return True
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
            self._isTestRunning = True
            self._product = productData
            self._activeStepIndex = 0
            
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

        if status:
            self.stopTest()


    def startCurrentStep(self):
        try:
            if self._isTestRunning == False:
                return

            if not len(self._product['steps']) > self._activeStepIndex:
                return

            activeStep = self._product['steps'][self._activeStepIndex]
            if activeStep and activeStep['camRecipe']:
                # print(self._activeStepIndex)
                self._stepStatus = True
                recipe = activeStep['camRecipe']
                
                if not recipe['recipeCode']:
                    self.__raiseError('Reçete No Bilgisi Girilmemiş')
                    return

                
                if self._stepStatus == False:
                    return

                # SELECT RECIPE FROM CAMERA
                recipeNoData = recipe['recipeCode'].split(':')
                # print('Reçete:' +  recipeNoData[1])
                camRes = self._camera.selectProgram(recipeNoData[0], recipeNoData[1])
                if not camRes:
                    self.__raiseError('Reçete Programı Seçilemedi')
                    self._camera.disconnect()
                    return

                if self._stepStatus == False:
                    self._camera.disconnect()
                    return

                # RESET ROBOT MOVEMENT FOR CAMERA TRIGGER
                rbToStartScanningData = recipe['rbToStartScanning'].split(':')
                self.__writeToRobot(rbToStartScanningData, 0)


                # SEND ROBOT GOTO START POSITION OF CURRENT STEP
                rbGotoPositionData = recipe['rbToRecipeStarted'].split(':')
                self.__writeToRobot(rbGotoPositionData, int(rbGotoPositionData[2]))
                self._robot.writeBit(3, 0)

                if self._stepStatus == False:
                    return

                # WAIT UNTIL ROBOT ARRIVES AT POSITION OF CURRENT STEP
                tryCount = 0
                arrivePosData = recipe['rbFromReadyToStart'].split(':')
                onPos = self.__readFromRobot(arrivePosData)
                while not onPos or int(onPos) != int(arrivePosData[2]):
                    onPos = self.__readFromRobot(arrivePosData)
                    # print('POZİSYON BAŞ VARIŞ: ' + str(onPos))
                    sleep(0.1)
                    tryCount = tryCount + 1
                    if tryCount > 300: # max timeout 10 sn
                        self._robot.writeInteger(0,0)
                        self._robot.writeBit(3, 1)
                        self._robot.writeBit(4, 1)
                        self.__raiseError('Robot Beklenen Pozisyona Getirilemedi.')
                        return

                self.__raiseStartPosArrived()

                # SEND ROBOT START TO SCAN
                self.__writeToRobot(rbToStartScanningData, int(rbToStartScanningData[2]))

                # APPLY RECIPE START DELAY
                if recipe['startDelay'] and int(recipe['startDelay'] > 0):
                    sleep(recipe['startDelay'] / 1000.0)

                if self._stepStatus == False:
                    return

                # ENABLE CAMERA TRIGGER
                trgResult = self._camera.triggerCamera()
                if not trgResult:
                    self.__raiseError('Kamerayı Otomatik(Run) Moda Alınız')
                    return

                if self._stepStatus == False:
                    return

                # WAIT UNTIL ROBOT SCAN MOVEMENT IS FINISHED
                tryCount = 0
                scanEndPosData = recipe['rbFromScanningFinished'].split(':')
                onPos = self.__readFromRobot(scanEndPosData)
                while not onPos or int(onPos) != int(scanEndPosData[2]):
                    if self._stepStatus == False:
                        return

                    onPos = self.__readFromRobot(scanEndPosData)
                    # print('POZİSYON BİTİŞ VARIŞ: ' + str(onPos))
                    sleep(0.1)
                    tryCount = tryCount + 1
                    if tryCount > 300: # max timeout 10 sn
                        self.__raiseError('Robot Bölge Taramasını Tamamlayamadı')
                        return

                # UPDATE! = WAIT UNTIL CAMERA OUTPUT IS READY
                # sleep(0.3)
                tryCount = 0
                isOutputReady = self._camera.isOutputReady()
                while isOutputReady == False:
                    if self._stepStatus == False:
                        return

                    isOutputReady = self._camera.isOutputReady()
                    sleep(0.1)

                    tryCount = tryCount + 1
                    if tryCount > 100:
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
                            testResult = camResult[int(resultFormat[0]) + int(bIndex * 4)] == 0
                            
                            if testResult == False:
                                break
                            bIndex = bIndex + 1
                except Exception:
                    pass

                # RESET PROGRAM
                self._robot.writeInteger(0, 0)
                sleep(0.1)
                self._robot.writeBit(3, 1)
                self._robot.writeBit(4, 0)

                self.__raiseStepResult(testResult, str(activeStep['id']))
                
                # sleep(10)  

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


    