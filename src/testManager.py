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


    def __moveNextStep(self):
        self._activeStepIndex = self._activeStepIndex + 1


    def __raiseError(self, msg):
        self.__stopTest()
        if self._backend:
            self._backend.raiseStepError(msg)


    def __raiseStepResult(self, result, msg):
        if self._backend:
            self._backend.raiseStepResult(result, msg)


    def __stopTest(self):
        self._activeStepIndex = 0


    def __createMaterials(self):
        if self._comConfig and self._updateMaterials == True:
            try:
                self.stopDevices()

                self._robot = Gp7Connector(self._comConfig['robotIp'], self._comConfig['robotPort'])
                self._camera = Cvx400(self._comConfig['cameraIp'])
            except Exception as e:
                print(e)


    def __checkAliveStatus(self) -> bool:
        return self.checkRobotIsAlive() and self.checkCameraIsAlive()


    def checkRobotIsAlive(self) -> bool:
        result = False
        try:
            if self._robot and self._robot.readInteger(0):
                result = True
        except:
            result = False

        return result


    def checkCameraIsAlive(self) -> bool:
        result = False

        try:
            if self._camera:
                self._camera.connect()
                result = self._camera.isAlive()
                self._camera.disconnect()
        except:
            result = False

        return result

    
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

    
    def initDevices(self, comConfig):
        if not self._comConfig or self._comConfig['robotIp'] != comConfig['robotIp'] or self._comConfig['robotPort'] != comConfig['robotPort'] or self._comConfig['cameraIp'] != comConfig['cameraIp']:
            self._updateMaterials = True
        self._comConfig = comConfig
        self.__createMaterials()


    def stopDevices(self):
        try:
            if self._camera:
                self._camera.disconnect()
        except:
            pass


    def startTest(self, productData):
        if self.__checkAliveStatus():
            self._product = productData
            
            if not self.__setRobotHome():
                self.__raiseError('Robot Başlatılamadı')
                return

            self._activeStepIndex = 0
            self.startCurrentStep()
        else:
            self.__raiseError('Robot ve Kamera İletişimini Kontrol Edin')


    def __setRobotHome(self) -> bool:
        result = False
        try:
            # RESET ALARM
            self._robot.resetAlarm()
            self._backend.raiseResetOk()
            sleep(0.5)

            self._robot.selectJob(self._comConfig['rbToMasterJob'])
            self._backend.raiseMasterJobOk()
            sleep(0.5)

            self._robot.setServoStatus(True)
            self._backend.raiseServoOnOk()
            sleep(0.5)

            self._robot.startJob()
            self._backend.raiseStartOk()

            # GOTO SAFETY HOME
            safetyHomeData = self._comConfig['rbToSafetyHome'].split(':')
            self.__writeToRobot(safetyHomeData, int(safetyHomeData[2]))

            # WAIT UNTIL ROBOT ARRIVES AT SAFETY HOME
            tryCount = 0
            arriveHomeData = self._comConfig['rbFromSafetyHome'].split(':')
            isHome = self.__readFromRobot(arriveHomeData)
            while not isHome or int(isHome) != int(arriveHomeData[2]):
                isHome = self.__readFromRobot(arriveHomeData)
                sleep(0.2)
                tryCount = tryCount + 1
                if tryCount > 25: # max timeout 5 sn
                    # self.__raiseError('Robot Home Pozisyona Getirilemedi.')
                    return False

            result = True
        except Exception as e:
            result = False
            # print(e)

        return result


    def startCurrentStep(self):
        try:
            activeStep = self._product['steps'][self._activeStepIndex]
            if activeStep and activeStep['camRecipe']:
                recipe = activeStep['camRecipe']
                
                if not recipe['recipeCode']:
                    self.__raiseError('Reçete No Bilgisi Girilmemiş')
                    return

                # SELECT RECIPE FROM CAMERA
                recipeNoData = recipe['recipeCode'].split(':')
                camRes = self._camera.selectProgram(recipeNoData[0], recipeNoData[1])
                if not camRes:
                    self.__raiseError('Reçete Programı Seçilemedi')
                    return

                # SEND ROBOT GOTO START POSITION OF CURRENT STEP
                rbGotoPositionData = recipe['rbToRecipeStarted'].split(':')
                self.__writeToRobot(rbGotoPositionData, int(rbGotoPositionData[2]))

                # WAIT UNTIL ROBOT ARRIVES AT POSITION OF CURRENT STEP
                tryCount = 0
                arrivePosData = recipe['rbFromReadyToStart'].split(':')
                onPos = self.__readFromRobot(arrivePosData)
                while not onPos or int(onPos) != int(arrivePosData[2]):
                    onPos = self.__readFromRobot(arrivePosData)
                    sleep(0.2)
                    tryCount = tryCount + 1
                    if tryCount > 50: # max timeout 10 sn
                        self.__raiseError('Robot Beklenen Pozisyona Getirilemedi.')
                        return

                # SEND ROBOT START TO SCAN
                rbToStartScanningData = recipe['rbToStartScanning'].split(':')
                self.__writeToRobot(rbToStartScanningData, int(rbToStartScanningData[2]))

                # APPLY RECIPE START DELAY
                if recipe['startDelay'] and int(recipe['startDelay'] > 0):
                    sleep(recipe['startDelay'] / 1000.0)

                # ENABLE CAMERA TRIGGER
                trgResult = self._camera.triggerCamera()
                if not trgResult:
                    self.__raiseError('Kamerayı Otomatik(Run) Moda Alınız')
                    return

                # WAIT UNTIL ROBOT SCAN MOVEMENT IS FINISHED
                tryCount = 0
                scanEndPosData = recipe['rbFromScanningFinished'].split(':')
                onPos = self.__readFromRobot(scanEndPosData)
                while not onPos or int(onPos) != int(scanEndPosData[2]):
                    onPos = self.__readFromRobot(scanEndPosData)
                    sleep(0.2)
                    tryCount = tryCount + 1
                    if tryCount > 50: # max timeout 10 sn
                        self.__raiseError('Robot Bölge Taramasını Tamamlayamadı')
                        return

                # DISABLE CAMERA TRIGGER
                self._camera.disableTrigger()

                # READ INSPECTION RESULTS
                testResult = False
                camResult = self._camera.readOutput()
                if camResult and len(camResult) > int(recipe['camResultByteIndex']):
                    testResult = camResult[int(recipe['camResultByteIndex'])] == 1

                self.__raiseStepResult(testResult, str(recipe['id']))                

                if testResult:
                    self.__moveNextStep()
                    self.startCurrentStep()
                else:
                    self.__stopTest()
            else:
                self.__raiseError('Test Adımı İçin Reçete Bilgisi Girilmemiş')
        except Exception as e:
            print(e)


    