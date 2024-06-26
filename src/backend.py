import os
from pathlib import Path
import sys
import json
from time import sleep
from PySide2.QtCore import QObject, Slot, Signal
from threading import Thread
from src.data_models import *
from src.hkThread import HekaThread
from src.testManager import TestManager
from src.dirManager import DirManager


class BackendManager(QObject):
    def __init__(self):
        QObject.__init__(self)
        self.initDb()
        self.testManager = TestManager(self)
        self.dirManager = DirManager(self)
        
        self.runCommChecker = False
        self.commChecker = None

        self.runSensorChecker = False
        self.sensorChecker = None

        self.runRobotHoldChecker = False
        self.robotHoldChecker = None

        self.lastRobotHoldStatus = False
        self.changingRobotHoldStatus = False

        self.runStartButtonListener = False
        self.startButtonChecker = None


    def initDb(self):
        create_tables()


    # region SIGNALS
    showSettings = Signal()
    showTestView = Signal()
    getSections = Signal(str)
    getState = Signal(str)

    saveProductFinished = Signal(str)
    getProductList = Signal(str)
    getProductInfo = Signal(str)
    deleteProductFinished = Signal(str)
    productListNeedsRefresh = Signal()
    productSelected = Signal(str)

    saveEmployeeFinished = Signal(str)
    getEmployeeList = Signal(str)
    getEmployeeInfo = Signal(str)
    deleteEmployeeFinished = Signal(str)
    employeeListNeedsRefresh = Signal()
    employeeSelected = Signal(str)
    employeeCardRead = Signal(str)

    saveShiftFinished = Signal(str)
    getShiftList = Signal(str)
    getShiftInfo = Signal(str)
    deleteShiftFinished = Signal(str)
    shiftListNeedsRefresh = Signal()
    shiftSelected = Signal(str)

    getSettings = Signal(str)
    saveSettingsFinished = Signal(str)

    testStepError = Signal(str)
    getStepResult = Signal(str)
    getDeviceStatus = Signal(str)

    getResetOk = Signal()
    getMasterJobOk = Signal()
    getServoOnOk = Signal()
    getStartOk = Signal()
    getAllStepsFinished = Signal()

    testResultSaved = Signal(str)
    getLiveStatus = Signal(str)
    getStartPosArrived = Signal()
    getProductSensor = Signal(bool)
    getNewImageResult = Signal(str, int)
    getCaptureImage = Signal(str)
    getRobotHoldChanged= Signal(bool)
    getReportStats = Signal(str)
    getRegionDetailResults = Signal(str)

    getStepVariables = Signal(str)
    saveStepVariableFinished = Signal(str)
    deleteStepVariableFinished = Signal(str)

    getSectionRegions = Signal(str)
    saveSectionRegionFinished = Signal(str)
    deleteSectionRegionFinished = Signal(str)

    oskRequested = Signal()
    oskClosed = Signal()

    getStartButtonPressed = Signal()
    # endregion
    
    # region THR FUNCTIONS
    def raiseStepError(self, msg):
        self.testStepError.emit(msg)
    
    def raiseStepResult(self, result, msg, detailedResult):
        msgObj = {
            'Result': result,
            'Message': msg,
            'Details': detailedResult,
        }
        self.getStepResult.emit(json.dumps(msgObj))
    
    def raiseResetOk(self):
        self.getResetOk.emit()

    def raiseMasterJobOk(self):
        self.getMasterJobOk.emit()

    def raiseServoOnOk(self):
        self.getServoOnOk.emit()

    def raiseStartOk(self):
        self.getStartOk.emit()

    def raiseAllStepsFinished(self):
        self.getAllStepsFinished.emit()

    def raiseStartPosArrived(self):
        self.getStartPosArrived.emit()

    def raiseNewImageResult(self, recipeDirectory, fullImagePath, recipeId):
        if fullImagePath and len(fullImagePath) > 0:
            self.getNewImageResult.emit(fullImagePath, recipeId)

    def __stopListeners(self):
        try:
            if self.dirManager:
                self.dirManager.stopListeners()

            if self.commChecker:
                self.runCommChecker = False
                self.commChecker.stop()
            
            if self.sensorChecker:
                self.runSensorChecker = False
                self.sensorChecker.stop()

            if self.robotHoldChecker:
                self.runRobotHoldChecker = False
                self.robotHoldChecker.stop()

            if self.startButtonChecker:
                self.runStartButtonListener = False
                self.startButtonChecker.stop()
        except Exception as e:
            print(e)
            pass

    def __listenForCommCheck(self):
        while self.runCommChecker:
            try:
                statusResult = {
                    'Robot': False,
                    'Camera': False,
                }

                statusResult["Robot"] = self.testManager.checkRobotIsAlive()
                statusResult["Camera"] = self.testManager.checkCameraIsAlive()

                self.getDeviceStatus.emit(json.dumps(statusResult))
            except Exception as e:
                # print(e)
                pass

            sleep(5)

    def __listenForProductSensor(self):
        while self.runSensorChecker:
            try:
                isFull = self.testManager.checkProductSensor()
                self.getProductSensor.emit(isFull)
            except:
                pass
            sleep(0.3)
    
    def __listenForRobotHold(self):
        while self.runRobotHoldChecker:
            try:
                if self.changingRobotHoldStatus == False:
                    liveStatus = self.testManager.readRobotStatus()['Hold']
                    if not liveStatus == None and liveStatus != self.lastRobotHoldStatus:
                        self.lastRobotHoldStatus = liveStatus
                        self.getRobotHoldChanged.emit(liveStatus)
            except:
                pass

            sleep(1)
    
    def __listenForStartButton(self):
        while self.runStartButtonListener:
            try:
                if self.testManager._isTestRunning == True:
                    self.runStartButtonListener = False
                    break

                startState = self.testManager.readStartButton()
                if startState == True:
                    self.runStartButtonListener = False
                    self.getStartButtonPressed.emit()
            except:
                pass
            sleep(0.1)

    # endregion

    # region COMM SLOTS
    @Slot(bool)
    def requestOsk(self, oskStatus):
        if oskStatus == True:
            tmpThr = HekaThread(target=self.__runEnableOsk)
            tmpThr.start()
        else:
            self.oskClosed.emit()

    
    def __runEnableOsk(self):
        sleep(0.2)
        self.oskRequested.emit()


    @Slot()
    def startCommCheck(self):
        self.runCommChecker = True
        if not self.commChecker:
            self.commChecker = HekaThread(target=self.__listenForCommCheck)
            self.commChecker.start()

        self.runRobotHoldChecker = True
        if not self.robotHoldChecker:
            self.robotHoldChecker = HekaThread(target=self.__listenForRobotHold)
            self.robotHoldChecker.start()


    @Slot()
    def startListenStartButton(self):
        self.runStartButtonListener = True
        try:
            if not self.startButtonChecker:
                self.startButtonChecker = HekaThread(target=self.__listenForStartButton)
            self.startButtonChecker.start()
        except:
            pass


    @Slot()
    def stopListenerForStartButton(self):
        self.runStartButtonListener = False
        if self.startButtonChecker:
            self.startButtonChecker = None


    @Slot()
    def startProductSensorCheck(self):
        self.runSensorChecker = True
        if not self.sensorChecker:
            self.sensorChecker = HekaThread(target=self.__listenForProductSensor)
            self.sensorChecker.start()
        

    @Slot()
    def initDevices(self):
        configData = getConfig()
        if configData:
            self.testManager.initDevices(configData)


    @Slot(int)
    def resetTest(self, productId):
        self.stopListenerForStartButton()
        sleep(0.1)

        localWork = HekaThread(target=(lambda: self.__resetTest(productId)))
        localWork.start()


    @Slot()
    def setRobotHold(self):
        self.changingRobotHoldStatus = True
        self.lastRobotHoldStatus = self.testManager.readRobotStatus()['Hold']
        nextStatus = not self.lastRobotHoldStatus
        self.testManager.setRobotHold(nextStatus)
        self.lastRobotHoldStatus = nextStatus
        self.changingRobotHoldStatus = False
        self.getRobotHoldChanged.emit(nextStatus)


    @Slot()
    def openHatch(self):
        #pass
        self.testManager.openHatch()

    
    @Slot()
    def closeHatch(self):
        #pass
        self.testManager.closeHatch(manuelClose=True)
        self.testManager.setVacuum(0)


    def __resetTest(self, productId):
        productData = getProduct(productId)
        if productData:
            stgModel = getConfig()
            self.testManager.setTestWithVacuum(stgModel['testWithVacuum'])
            self.testManager.setTestWithCloseHatch(stgModel['testWithCloseHatch'])

            globalVars = getAllVariableList()
            if globalVars:
                self.testManager.setGlobalVars(globalVars)

            self.testManager.startTest(productData)
    # endregion

    # SLOTS
    @Slot()
    def appIsClosing(self):
        self.__stopListeners()


    @Slot()
    def requestShowSettings(self):
        self.showSettings.emit()

    @Slot()
    def requestShowTest(self):
        self.showTestView.emit()


    @Slot(str)
    def saveTestResult(self, model):
        result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
        modelData = json.loads(model)
        if modelData:
            result = saveTestResult(modelData)
        self.testResultSaved.emit(json.dumps(result))


    @Slot(int)
    def requestSections(self, productId):
        sampleData = [
            {
                "Label": "1",
                "PosX": 200,
                "PosY": 60,
            },
            {
                "Label": "2",
                "PosX": 200,
                "PosY": 40,
            },
            {
                "Label": "3",
                "PosX": 450,
                "PosY": 100,
            }
        ]
        self.getSections.emit(json.dumps(sampleData))


    @Slot()
    def requestState(self):
        sampleData = [
            {
                "Section": "Serigrafi Açı Kontrolü",
                "Status": True,
                "FaultCount": 0,
            },
            {
                "Section": "Serigrafi Baskı Hatası",
                "Status": True,
                "FaultCount": 0,
            },
            {
                "Section": "Kapak Bölge 1",
                "Status": False,
                "FaultCount": 5,
            },
            {
                "Section": "Kapak Bölge 2",
                "Status": True,
                "FaultCount": 3,
            },
            {
                "Section": "Gövde Sağ",
                "Status": True,
                "FaultCount": 0,
            },
            {
                "Section": "Gövde Sol",
                "Status": True,
                "FaultCount": 0,
            },
            {
                "Section": "Gövde Ön",
                "Status": True,
                "FaultCount": 8,
            },
            {
                "Section": "İç Gövde 1",
                "Status": False,
                "FaultCount": 13,
            },
            {
                "Section": "İç Gövde 2",
                "Status": True,
                "FaultCount": 0,
            }
        ]
        self.getState.emit(json.dumps(sampleData))


    @Slot(int, str, str)
    def requestRegionResults(self, sectionId, startDate, endDate):
        data = getSectionRegionResults(sectionId, startDate, endDate)
        if data:
            self.getRegionDetailResults.emit(json.dumps(data))


    @Slot(int, int)
    def requestLiveStatus(self, productId, shiftId):
        data = getLiveStats(productId if productId > 0 else None, shiftId if shiftId > 0 else None)
        if data:
            self.getLiveStatus.emit(json.dumps(data))


    @Slot(str, str)
    def requestReportStats(self, startDate, endDate):
        data = getReportStats(startDate, endDate)
        if data:
            self.getReportStats.emit(json.dumps(data))


    @Slot(str)
    def requestCaptureImage(self, camImage: str):
        if self.dirManager:
            camImage = camImage.replace('file://', '')
            print('REQUESTED CAPTURE IMAGE: ' + camImage)
            captureImage = self.dirManager.getCaptureImage(camImage)
            if captureImage:
                self.getCaptureImage.emit(captureImage)

    
    # region VARIABLE SLOTS
    @Slot(int)
    def requestStepVariables(self, stepId: int):
        data = getVariableList(stepId)
        if data:
            self.getStepVariables.emit(json.dumps(data))

    @Slot(int, str)
    def saveStepVariables(self, stepId: int, data: str):
        data = saveStepVariables(stepId, json.loads(data))
        if data:
            self.saveStepVariableFinished.emit(json.dumps(data))

    @Slot(int)
    def deleteVariable(self, variableId: int):
        data = deleteVariable(variableId)
        if data:
            self.deleteStepVariableFinished.emit(json.loads(data))
    # endregion


     # region SECTION REGION SLOTS
    @Slot(int)
    def requestSectionRegions(self, sectionId: int):
        data = getSectionRegionList(sectionId)
        if data:
            self.getSectionRegions.emit(json.dumps(data))

    @Slot(int, str)
    def saveSectionRegions(self, sectionId: int, data: str):
        data = saveSectionRegions(sectionId, json.loads(data))
        if data:
            self.saveSectionRegionFinished.emit(json.dumps(data))

    @Slot(int)
    def deleteSectionRegion(self, regionId: int):
        data = deleteVariable(regionId)
        if data:
            self.deleteSectionRegionFinished.emit(json.loads(data))
    # endregion



    # PRODUCT SLOTS
    @Slot()
    def requestProductList(self):
        data = getProductList()
        self.getProductList.emit(json.dumps(data))


    @Slot(int)
    def requestProductInfo(self, productId):
        if productId == -1:
            prList = getProductList()
            if len(prList) == 1:
                productId = prList[0]['id']

        data = getProduct(productId)
        if data and data['id'] > 0:
            rcpArr = []
            dirArr = []
            for rcp in data['recipes']:
                if rcp['imageDir'] and len(str(rcp['imageDir'])) > 0:
                    rcpArr.append(rcp['id'])
                    dirArr.append(rcp['imageDir'])

            self.dirManager.stopListeners()
            self.dirManager.setRecipes(rcpArr)
            self.dirManager.setDirectories(dirArr)

            self.dirManager.startListeners()

        self.getProductInfo.emit(json.dumps(data))


    @Slot(str)
    def saveProduct(self, model):
        modelData = json.loads(model)
        procResult = saveOrUpdateProduct(modelData)
        self.saveProductFinished.emit(json.dumps(procResult))


    @Slot(int)
    def deleteProduct(self, productId):
        procResult = deleteProduct(productId)
        self.deleteProductFinished.emit(json.dumps(procResult))


    @Slot(int)
    def broadcastProductSelected(self, productId):
        data = getProduct(productId)
        if data:
            self.productSelected.emit(json.dumps(data))


    @Slot()
    def broadcastProductListRefresh(self):
        self.productListNeedsRefresh.emit()
        

    # EMPLOYEE SLOTS
    @Slot()
    def requestEmployeeList(self):
        data = getEmployeeList()
        self.getEmployeeList.emit(json.dumps(data))


    @Slot(int)
    def requestEmployeeInfo(self, employeeId):
        data = getEmployee(employeeId)
        self.getEmployeeInfo.emit(json.dumps(data))


    @Slot(str)
    def requestEmployeeCard(self, cardNo):
        data = getEmployeeByCard(cardNo)
        self.employeeCardRead.emit(json.dumps(data))


    @Slot(str)
    def saveEmployee(self, model):
        modelData = json.loads(model)
        procResult = saveOrUpdateEmployee(modelData)
        self.saveEmployeeFinished.emit(json.dumps(procResult))


    @Slot(int)
    def deleteEmployee(self, employeeId):
        procResult = deleteEmployee(employeeId)
        self.deleteEmployeeFinished.emit(json.dumps(procResult))


    @Slot(int)
    def broadcastEmployeeSelected(self, employeeId):
        data = getEmployee(employeeId)
        if data:
            self.employeeSelected.emit(json.dumps(data))
    

    @Slot()
    def broadcastEmployeeListRefresh(self):
        self.employeeListNeedsRefresh.emit()


    # SHIFT SLOTS
    @Slot()
    def requestShiftList(self):
        data = getShiftList()
        self.getShiftList.emit(json.dumps(data))


    @Slot(int)
    def requestShiftInfo(self, shiftId):
        data = getShift(shiftId)
        self.getShiftInfo.emit(json.dumps(data))


    @Slot(str)
    def saveShift(self, model):
        modelData = json.loads(model)
        procResult = saveOrUpdateShift(modelData)
        self.saveShiftFinished.emit(json.dumps(procResult))


    @Slot(int)
    def deleteShift(self, shiftId):
        procResult = deleteShift(shiftId)
        self.deleteShiftFinished.emit(json.dumps(procResult))


    @Slot(int)
    def broadcastShiftSelected(self, shiftId):
        data = getShift(shiftId)
        if data:
            self.shiftSelected.emit(json.dumps(data))

    
    @Slot()
    def broadcastShiftListRefresh(self):
        self.shiftListNeedsRefresh.emit()


    # SETTINGS SLOTS
    @Slot()
    def requestSettings(self):
        stgModel = getConfig()
        self.getSettings.emit(json.dumps(stgModel))


    @Slot(str)
    def saveSettings(self, model):
        data = json.loads(model)
        postResult = saveConfig(data)
        self.saveSettingsFinished.emit(json.dumps(postResult))
        
