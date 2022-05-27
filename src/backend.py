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

        # test case for dir manager
        self.dirManager.setDirectories(['/home/hakan/FtpContent/VisionDB/XG-X00DEMO_00_01_FC_C2_9C_82/SD1/0002/Image',
            '/home/hakan/FtpContent/VisionDB/XG-X00DEMO_00_01_FC_C2_9C_82/SD1/0003/Image'])
        self.dirManager.startListeners()


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
    getNewImageResult = Signal(str)
    # endregion
    
    # region THR FUNCTIONS
    def raiseStepError(self, msg):
        self.testStepError.emit(msg)
    
    def raiseStepResult(self, result, msg):
        msgObj = {
            'Result': result,
            'Message': msg,
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

    def raiseNewImageResult(self, recipeDirectory, fullImagePath):
        if fullImagePath and len(fullImagePath) > 0:
            self.getNewImageResult.emit(fullImagePath)

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
        except:
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
                print(e)
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
    
    
    # endregion

    # COMM SLOTS
    @Slot()
    def startCommCheck(self):
        self.runCommChecker = True
        if not self.commChecker:
            self.commChecker = HekaThread(target=self.__listenForCommCheck)
            self.commChecker.start()


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
        localWork = HekaThread(target=(lambda: self.__resetTest(productId)))
        localWork.start()


    @Slot()
    def setRobotHold(self):
        self.testManager.setRobotHold(True)


    def __resetTest(self, productId):
        productData = getProduct(productId)
        if productData:
            self.testManager.startTest(productData)


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


    @Slot(int, int)
    def requestLiveStatus(self, productId, shiftId):
        data = getLiveStats(productId if productId > 0 else None, shiftId if shiftId > 0 else None)
        if data:
            self.getLiveStatus.emit(json.dumps(data))


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
        
