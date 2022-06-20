from datetime import time, datetime, timedelta
from peewee import *
from playhouse.shortcuts import model_to_dict, dict_to_model
from src.printManager import PrintManager


db = SqliteDatabase('data/heka.db')
printer = PrintManager()


def create_tables():
    with db:
        db.create_tables([Product, Employee, Shift, 
            ProductSection, ProductCamRecipe, ProductTestStep, 
            TestResult, TestResultImage,LiveResult, LiveProduction, ComConfig, StepVariable, TestResultStepRegion, ProductSectionRegion])

# PRODUCT CRUD
def getProductList():
    data = []
    try:
        rawData = Product.select().dicts()
        data = list(rawData)
    except:
        pass
    return data


def getProduct(productId):
    data = None
    try:
        rawData = Product.select(Product.id, Product.productNo, Product.productName, Product.gridWidth, Product.gridHeight,
            Product.isActive, Product.imagePath).where(Product.id == productId).get()
        data = model_to_dict(rawData, backrefs = False)

        rawSections = ProductSection.select(ProductSection.id, ProductSection.sectionName, ProductSection.orderNo,
            ProductSection.posX, ProductSection.posY, ProductSection.sectionWidth, ProductSection.sectionHeight,
            ProductSection.areaNo, ProductSection.areaInfo, ProductSection.productCamRecipe).join(Product).where(Product.id == productId).dicts()
        data['sections'] = list(rawSections)

        rawRecipes = ProductCamRecipe.select(ProductCamRecipe.id, ProductCamRecipe.recipeCode, ProductCamRecipe.rbToRecipeStarted,
                    ProductCamRecipe.rbFromReadyToStart, ProductCamRecipe.rbToStartScanning, ProductCamRecipe.rbFromScanningFinished,
                    ProductCamRecipe.camResultByteIndex, ProductCamRecipe.camResultFormat,  ProductCamRecipe.startDelay,
                    ProductCamRecipe.orderNo, ProductCamRecipe.imageDir).where(ProductCamRecipe.product == productId).dicts()
        data['recipes'] = list(rawRecipes)

        rawSteps = ProductTestStep.select().join(Product).where(Product.id == productId).dicts()
        listSteps = rawSteps
        for st in listSteps:
            if st['section']:
                st['sectionId'] = int(st['section'])
                sectObj:ProductSection = ProductSection.get(ProductSection.id == int(st['section']))
                st['sectionName'] = sectObj.sectionName
            else:
                st['sectionId'] = None
                st['sectionName'] = ''
            
            if st['productCamRecipe']:
                st['camRecipeId'] = int(st['productCamRecipe'])
                rawRecipe = ProductCamRecipe.select(ProductCamRecipe.id, ProductCamRecipe.recipeCode, ProductCamRecipe.rbToRecipeStarted,
                    ProductCamRecipe.rbFromReadyToStart, ProductCamRecipe.rbToStartScanning, ProductCamRecipe.rbFromScanningFinished, ProductCamRecipe.startDelay,
                    ProductCamRecipe.camResultByteIndex, ProductCamRecipe.camResultFormat, ProductCamRecipe.orderNo, ProductCamRecipe.imageDir).where(
                        ProductCamRecipe.id == int(st['productCamRecipe'])).get()

                recipeObj = model_to_dict(rawRecipe, backrefs= False)

                recipeObj['results'] = None
                recipeObj['testresult_set'] = None
                recipeObj['liveproduction_set'] = None
                recipeObj['sections'] = None
                recipeObj['product'] = None
                recipeObj['steps'] = None
                st['camRecipe'] = recipeObj
            else:
                st['camRecipeId'] = None

            st['liveStatus'] = False
            st['liveResult'] = False
            st['product'] = None
            st['section'] = None
            # st['camRecipe'] = None
            st['productCamRecipe'] = None
            
        data['steps'] = sorted(list(listSteps), key=lambda x: x['orderNo'], reverse=False) 
        data['camRecipes'] = None
        # print(data)
    except Exception as e:
        print(e)
        pass
    return data


def saveOrUpdateProduct(model):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj = None
        try:
            dbObj = Product.get(Product.id == int(model['id']))
        except:
            pass
        
        if not dbObj:
            dbObj = Product()

        dbObj.productNo = model['productNo']
        dbObj.productName = model['productName']
        dbObj.imagePath = model['imagePath']
        dbObj.gridWidth = model['gridWidth']
        dbObj.gridHeight = model['gridHeight']
        dbObj.isActive = True
        
        dbObj.save()

        # save sections
        if model['sections']:
            existingSections = ProductSection.select().join(Product).where(Product.id == dbObj.id).dicts()
            if existingSections:
                deletedSections = list(filter(lambda d: len(list(filter(lambda c: c['id'] == d['id'], model['sections']))) == 0, existingSections))
                for d in deletedSections:
                    dbObjToDelete:ProductSection = ProductSection.get(ProductSection.id == d['id'])
                    dbObjToDelete.delete_instance()

            for d in model['sections']:
                dbSection = None
                try:
                    dbSection = ProductSection.get(ProductSection.id == d['id'])
                except:
                    pass

                if not dbSection:
                    dbSection = ProductSection()

                dbSection.areaNo = d['areaNo']
                dbSection.orderNo = d['orderNo']
                dbSection.sectionName = d['sectionName']
                dbSection.posX = d['posX']
                dbSection.posY = d['posY']
                dbSection.sectionWidth = d['sectionWidth']
                dbSection.sectionHeight = d['sectionHeight']
                dbSection.product = dbObj
                dbSection.save()

        # save recipes
        if model['recipes']:
            existingRecipes = ProductCamRecipe.select().join(Product).where(Product.id == dbObj.id).dicts()
            if existingRecipes:
                deletedRecipes = list(filter(lambda d: len(list(filter(lambda c: c['id'] == d['id'], model['recipes']))) == 0, existingRecipes))
                for d in deletedRecipes:
                    dbObjToDelete:ProductCamRecipe = ProductCamRecipe.get(ProductCamRecipe.id == d['id'])
                    dbObjToDelete.delete_instance()

            for d in model['recipes']:
                dbRecipe:ProductCamRecipe = None
                try:
                    dbRecipe = ProductCamRecipe.get(ProductCamRecipe.id == d['id'])
                except:
                    pass

                if not dbRecipe:
                    dbRecipe = ProductCamRecipe()

                dbRecipe.recipeCode = d['recipeCode']
                dbRecipe.camResultByteIndex = 0 #int(d['camResultByteIndex']) if d['camResultByteIndex'] else 0
                dbRecipe.rbFromReadyToStart = d['rbFromReadyToStart']
                dbRecipe.rbFromScanningFinished = d['rbFromScanningFinished']
                dbRecipe.rbToRecipeStarted = d['rbToRecipeStarted']
                dbRecipe.rbToStartScanning = d['rbToStartScanning']
                dbRecipe.startDelay = d['startDelay']
                dbRecipe.camResultFormat = str(d['camResultFormat']) if d['camResultFormat'] else ''
                dbRecipe.orderNo = 0
                dbRecipe.product = dbObj
                dbRecipe.imageDir = str(d['imageDir']) if d['imageDir'] else None
                dbRecipe.save()

         # save steps
        if model['steps']:
            existingSteps = ProductTestStep.select().join(Product).where(Product.id == dbObj.id).dicts()
            if existingSteps:
                deletedSteps = list(filter(lambda d: len(list(filter(lambda c: c['id'] == d['id'], model['steps']))) == 0, existingSteps))
                for d in deletedSteps:
                    dbObjToDelete:ProductTestStep = ProductTestStep.get(ProductTestStep.id == d['id'])
                    dbObjToDelete.delete_instance()

            for d in model['steps']:
                dbStep:ProductTestStep = None
                try:
                    dbStep = ProductTestStep.get(ProductTestStep.id == d['id'])
                except:
                    pass

                if not dbStep:
                    dbStep = ProductTestStep()

                dbStep.testName = d['testName']
                dbStep.orderNo = d['orderNo']
                dbStep.section = ProductSection.get(ProductSection.id == d['sectionId'])
                dbStep.productCamRecipe = ProductCamRecipe.get(ProductCamRecipe.id == d['camRecipeId'])
                dbStep.product = dbObj
                dbStep.isActive = True
                dbStep.save()


        result['Result'] = True
        result['RecordId'] = dbObj.id
    except Exception as e:
        print(e)
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result


def deleteProduct(productId):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj = Product.get(Product.id == productId)

        testCount = TestResult.select().join(Product).where(Product.id == productId).count()

        if testCount > 0:
            dbObj.isActive = False
            dbObj.save()
        else:
            # clear sections
            try:
                sections = ProductSection.select().join(Product).where(Product.id == productId)
                if sections and len(sections) > 0:
                    for s in sections:
                        s.delete_instance()
            except:
                pass

            # clear steps
            try:
                steps = ProductTestStep.select().join(Product).where(Product.id == productId)
                if steps and len(steps) > 0:
                    for s in steps:
                        s.delete_instance()
            except:
                pass
            
            dbObj.delete_instance()

        result['Result'] = True
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result


# VARIABLE CRUD
def getVariableList(stepId: int):
    data = []
    try:
        rawData = StepVariable.select().where(StepVariable.step == stepId).dicts()
        data = list(rawData)
    except:
        pass
    return data


def getAllVariableList():
    data = []
    try:
        rawData = StepVariable.select().dicts()
        data = list(rawData)
    except:
        pass
    return data


def saveStepVariables(stepId: int, varList):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        for d in varList:
            dbVar:StepVariable = None
            try:
                dbVar = StepVariable.get(StepVariable.id == d['id'])
            except:
                pass

            sameVarExists = True
            try:
                dbOther = StepVariable.get((StepVariable.id != d['id']) & (StepVariable.variableName == d['variableName']))
                if not dbOther:
                    sameVarExists = False
            except:
                sameVarExists = False

            if sameVarExists == True:
                continue

            if not dbVar:
                dbVar = StepVariable()

            dbVar.variableName = d['variableName']
            dbVar.variableValue = d['variableValue']
            dbVar.description = d['description']
            dbVar.step = ProductTestStep.get(ProductTestStep.id == stepId)
            dbVar.save()

        result['Result'] = True
    except Exception as e:
        print(e)
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result


def deleteVariable(variableId: int):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbVar:StepVariable = StepVariable.get(StepVariable.id == variableId)

        if dbVar:
            dbVar.delete_instance()

        result['Result'] = True
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)
    return result


# SECTION REGION CRUD
def getSectionRegionList(sectionId: int):
    data = []
    try:
        rawData = ProductSectionRegion.select().where(ProductSectionRegion.section == sectionId).dicts()
        data = list(rawData)
    except:
        pass
    return data


def saveSectionRegions(sectionId: int, regionList):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        for d in regionList:
            dbVar:ProductSectionRegion = None
            try:
                dbVar = ProductSectionRegion.get(ProductSectionRegion.id == d['id'])
            except:
                pass

            sameVarExists = True
            try:
                dbOther = ProductSectionRegion.get((ProductSectionRegion.id != d['id']) & (ProductSectionRegion.regionName == d['regionName']))
                if not dbOther:
                    sameVarExists = False
            except:
                sameVarExists = False

            if sameVarExists == True:
                continue

            if not dbVar:
                dbVar = ProductSectionRegion()

            dbVar.regionName = d['regionName']
            dbVar.byteIndex = d['byteIndex']
            dbVar.posX = d['posX']
            dbVar.posY = d['posY']
            dbVar.width = d['width']
            dbVar.height = d['height']
            dbVar.section = ProductSection.get(ProductSection.id == sectionId)
            dbVar.save()

        result['Result'] = True
    except Exception as e:
        print(e)
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result


def deleteSectionRegion(regionId: int):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbVar:ProductSectionRegion = ProductSectionRegion.get(ProductSectionRegion.id == regionId)

        if dbVar:
            dbVar.delete_instance()

        result['Result'] = True
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)
    return result


def getSectionRegionResults(sectionId: int, dateStrStart: str, dateStrEnd: str):
    result = None
    try:
        dtStartParts = dateStrStart.split('.')
        dtEndParts = dateStrEnd.split('.')

        dtStart = dtStartParts[2] + '-' + dtStartParts[1] + '-' + dtStartParts[0]
        dtEnd = dtEndParts[2] + '-' + dtEndParts[1] + '-' + dtEndParts[0]
        tmpDate:datetime = (datetime.strptime(dtEnd, '%Y-%m-%d') + timedelta(days=1))
        dtEnd = tmpDate.strftime('%Y-%m-%d')

        result = {}

        # section based region defect data
        regionData = list(TestResultStepRegion.select(ProductSectionRegion.id, ProductSectionRegion.posX, ProductSectionRegion.posY,\
                ProductSectionRegion.width, ProductSectionRegion.height, fn.COUNT().alias('count'))\
            .join(ProductSectionRegion)\
            .switch(TestResultStepRegion)\
            .join(TestResultImage)\
            .join(TestResult)\
            .where((TestResult.testDate >= dtStart) & (TestResult.testDate < dtEnd) & (TestResultStepRegion.isOk == False) &\
                (TestResultStepRegion.productSectionRegion > 0) & (ProductSectionRegion.section == sectionId))\
                .group_by(ProductSectionRegion).dicts())

        regionsOfData = list(map(lambda x: x['id'], regionData))

        try:
            otherRegions = list(ProductSectionRegion.select(ProductSectionRegion.id, ProductSectionRegion.posX, ProductSectionRegion.posY,\
                ProductSectionRegion.width, ProductSectionRegion.height).where((ProductSectionRegion.section == sectionId) & ((ProductSectionRegion.id << regionsOfData) == False)).dicts())
            for oRegion in otherRegions:
                oRegion['count'] = 0
                regionData.append(oRegion)
        except:
            pass

        result['Data'] = regionData
    except Exception as e:
        print(e)
        pass

    return result

# region EMPLOYEE CRUD
def getEmployeeList():
    data = []
    try:
        rawData = Employee.select().dicts()
        data = list(rawData)
    except:
        pass
    return data


def getEmployee(employeeId):
    data = None
    try:
        rawData = Employee.select(Employee.id, Employee.employeeCode, Employee.employeeName, Employee.isActive).where(Employee.id == employeeId).get()
        data = model_to_dict(rawData, backrefs = False)
        data['testresult_set'] = None
        data['liveproduction_set'] = None
    except:
        pass
    return data


def getEmployeeByCard(cardNo):
    data = None
    try:
        rawData = Employee.select(Employee.id, Employee.employeeCode, Employee.employeeName, Employee.isActive).where(Employee.employeeCode == cardNo).get()
        data = model_to_dict(rawData, backrefs = False)
        data['testresult_set'] = None
        data['liveproduction_set'] = None
    except:
        pass
    return data


def saveOrUpdateEmployee(model):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj = None
        try:
            dbObj = Employee.get(Employee.id == int(model['id']))
        except:
            pass
        
        if not dbObj:
            dbObj = Employee()

        dbObj.employeeCode = model['employeeCode']
        dbObj.employeeName = model['employeeName']
        dbObj.isActive = True
        
        dbObj.save()

        result['Result'] = True
        result['RecordId'] = dbObj.id
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result


def deleteEmployee(employeeId):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj = Employee.get(Employee.id == employeeId)

        testCount = TestResult.select().join(Employee).where(Employee.id == employeeId).count()

        if testCount > 0:
            dbObj.isActive = False
            dbObj.save()
        else:
            dbObj.delete_instance()

        result['Result'] = True
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result
# endregion

# region SHIFT CRUD
def getShiftList():
    data = []
    try:
        rawData = Shift.select().dicts()
        data = list(rawData)

        for d in data:
            if d['startTime']:
                to = d['startTime']
                d['startTime'] = str(to.hour).zfill(2) + ':' + str(to.minute).zfill(2)
            else:
                d['startTime'] = ''

            if d['endTime']:
                to = d['endTime']
                d['endTime'] = str(to.hour).zfill(2) + ':' + str(to.minute).zfill(2)
            else:
                d['endTime'] = ''

    except:
        pass
    return data


def getShift(shiftId):
    data = None
    try:
        rawData = Shift.select(Shift.id, Shift.shiftCode, Shift.startTime, Shift.endTime).where(Shift.id == shiftId).get()
        data = model_to_dict(rawData, backrefs = False)
        data['testresult_set'] = None
        data['liveproduction_set'] = None

        if data['startTime']:
            to = data['startTime']
            data['startTime'] = str(to.hour).zfill(2) + ':' + str(to.minute).zfill(2)
        else:
            data['startTime'] = ''

        if data['endTime']:
            to = data['endTime']
            data['endTime'] = str(to.hour).zfill(2) + ':' + str(to.minute).zfill(2)
        else:
            data['endTime'] = ''

    except:
        pass
    return data


def saveOrUpdateShift(model):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj = None
        try:
            dbObj = Shift.get(Shift.id == int(model['id']))
        except:
            pass
        
        if not dbObj:
            dbObj = Shift()

        stData = str(model['startTime']).split(':')
        enData = str(model['endTime']).split(':')

        dbObj.shiftCode = model['shiftCode']
        dbObj.startTime = time(int(stData[0]), int(stData[1]), 0)
        dbObj.endTime = time(int(enData[0]), int(enData[1]), 0)
        dbObj.isActive = True
        
        dbObj.save()

        result['Result'] = True
        result['RecordId'] = dbObj.id
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result


def deleteShift(shiftId):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj = Shift.get(Shift.id == shiftId)

        testCount = TestResult.select().join(Shift).where(Shift.id == shiftId).count()

        if testCount > 0:
            dbObj.isActive = False
            dbObj.save()
        else:
            dbObj.delete_instance()

        result['Result'] = True
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result
# endregion

# TEST RESULTS CRUD
def saveTestResult(model, printAfterSave = True):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj = TestResult()

        dbObj.testDate = datetime.now()
        dbObj.product = Product.get(Product.id == model['productId'])
        dbObj.barcode = ''
        dbObj.section = ProductSection.get(ProductSection.id == model['sectionId']) if not model['sectionId'] == None else None
        dbObj.step = ProductTestStep.get(ProductTestStep.id == model['stepId']) if not model['stepId'] == None else None
        dbObj.shift = Shift.get(Shift.id == model['shiftId']) if not model['shiftId'] == None else None
        dbObj.employee = Employee.get(Employee.id == model['employeeId']) if not model['employeeId'] == None else None
        dbObj.isOk = model['isOk']

        dtNow = datetime.now().strftime('%Y-%m-%d')
        dtEnd = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')

        currentCount = TestResult.select()\
            .where((TestResult.testDate >= dtNow) & (TestResult.testDate < dtEnd))\
            .count()
        productSerial = datetime.now().strftime('%Y%m%d%H%M') + str(currentCount + 1).zfill(5)
        dbObj.barcode = productSerial
        
        dbObj.save()

        # save step details and images
        if "steps" in model.keys() and not model['steps'] == None:
            for st in model['steps']:
                relatedImages = []
                stepImagePath = ''
                filteredSections = list(filter(lambda x: x['id'] == st['sectionId'], model['sections']))
                if filteredSections and len(filteredSections) > 0:
                    relatedImages = filteredSections[0]['images']
                    for rImg in relatedImages:
                        stepImagePath = stepImagePath + rImg + ';' 

                stepObj = TestResultImage()
                stepObj.imagePath = stepImagePath
                stepObj.testResult = dbObj
                stepObj.step = ProductTestStep.get(ProductTestStep.id == st['id'])
                stepObj.stepResult = st['liveResult']
                stepObj.save()

                # save section region results of current step
                if st['detailResult']:
                    byteIndex = 0
                    for dRes in st['detailResult']:
                        dbRegionResult = TestResultStepRegion()
                        dbRegionResult.byteIndex = byteIndex
                        dbRegionResult.isOk = dRes
                        dbRegionResult.testResultImage = stepObj
                        try:
                            dbRegionResult.productSectionRegion = ProductSectionRegion.get((ProductSectionRegion.section == st['sectionId'])\
                                & ((ProductSectionRegion.byteIndex) < 10 & (ProductSectionRegion.byteIndex == byteIndex))\
                                    | ((ProductSectionRegion.byteIndex > 10) & (ProductSectionRegion.byteIndex == (byteIndex / 10)) | (ProductSectionRegion.byteIndex == (byteIndex % 10)) )\
                                )
                        except:
                            pass
                        dbRegionResult.save()
                        byteIndex = byteIndex + 1
                

        result['Result'] = True
        result['RecordId'] = dbObj.id

        if printAfterSave == True:
            empObj = model_to_dict(Employee.select(Employee.employeeName).where(Employee.id == model['employeeId']).get())
            shiftObj = model_to_dict(Shift.select(Shift.shiftCode).where(Shift.id == model['shiftId']).get())
            printer.printLabel({
                'employeeName': empObj['employeeName'],
                'result': model['isOk'],
                'shiftCode': shiftObj['shiftCode'],
                'barcode': productSerial,
            })
    except Exception as e:
        result['Result'] = False
        result['ErrorMessage'] = str(e)

    return result


def getLiveStats(productId = None, shiftId = None):
    # shift based: total test, total fault count
    # product based: per step fault count
    result = { 'Live': { }, 'Steps': [] }

    try:
        dtNow = datetime.now().strftime('%Y-%m-%d')
        dtEnd = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')

        # shift based data
        okCount = TestResult.select().where((TestResult.shift == shiftId) & (TestResult.testDate >= dtNow) & (TestResult.testDate < dtEnd) & (TestResult.isOk == True)).count()
        nokCount = TestResult.select().where((TestResult.shift == shiftId) & (TestResult.testDate >= dtNow) & (TestResult.testDate < dtEnd) & (TestResult.isOk == False)).count()

        result['Live']['totalCount'] = okCount + nokCount
        result['Live']['faultCount'] = nokCount

        # product based data
        if productId:
            prData = getProduct(productId)
            if prData and prData['steps']:
                for st in prData['steps']:
                    st['faultCount'] = TestResultImage.select().join(TestResult).where((TestResult.shift == shiftId) & (TestResult.product == productId) 
                        & (TestResult.testDate >= dtNow) & (TestResult.testDate < dtEnd) 
                        & (TestResultImage.stepResult == False) & (TestResultImage.step == st['id'])).count()
                    result['Steps'].append(st)
    except:
        pass
    
    return result


def getReportStats(dateStrStart: str, dateStrEnd: str):
    result = None
    try:
        dtStartParts = dateStrStart.split('.')
        dtEndParts = dateStrEnd.split('.')

        dtStart = dtStartParts[2] + '-' + dtStartParts[1] + '-' + dtStartParts[0]
        dtEnd = dtEndParts[2] + '-' + dtEndParts[1] + '-' + dtEndParts[0]
        tmpDate:datetime = (datetime.strptime(dtEnd, '%Y-%m-%d') + timedelta(days=1))
        dtEnd = tmpDate.strftime('%Y-%m-%d')

        # shift based table
        shiftData = list(TestResult.select(Shift.id, Shift.shiftCode, fn.COUNT().alias('count'))\
            .join(Shift).where((TestResult.testDate >= dtStart) & (TestResult.testDate < dtEnd)).group_by(Shift.id, Shift.shiftCode).dicts())
        for sh in shiftData:
            sh['okCount'] = TestResult.select().where((TestResult.testDate >= dtStart) & (TestResult.testDate < dtEnd) & (TestResult.isOk == True) & (TestResult.shift == sh['id'])).count()
            sh['nokCount'] = TestResult.select().where((TestResult.testDate >= dtStart) & (TestResult.testDate < dtEnd) & (TestResult.isOk == False) & (TestResult.shift == sh['id'])).count()


        # employee based table
        employeeData = list(TestResult.select(Employee.id, Employee.employeeName, fn.COUNT(TestResult.id).alias('count'))\
            .join(Employee).where((TestResult.testDate >= dtStart) & (TestResult.testDate <= dtEnd)).group_by(Employee).dicts())
        for emp in employeeData:
            emp['okCount'] = TestResult.select().where((TestResult.testDate >= dtStart) & (TestResult.testDate < dtEnd) & (TestResult.isOk == True) & (TestResult.employee == emp['id'])).count()
            emp['nokCount'] = TestResult.select().where((TestResult.testDate >= dtStart) & (TestResult.testDate < dtEnd) & (TestResult.isOk == False) & (TestResult.employee == emp['id'])).count()


        # steps based pie data
        stepsData = list(TestResultImage.select(ProductTestStep.section, ProductTestStep.testName, fn.COUNT(TestResultImage.id).alias('count'))\
            .join(ProductTestStep).switch(TestResultImage).join(TestResult).where((TestResult.testDate >= dtStart) &\
                 (TestResult.testDate < dtEnd) & (TestResultImage.stepResult == False)).group_by(ProductTestStep).dicts())


        # split first step into two sub parts
        abstractPlaceCount = TestResultStepRegion.select().join(TestResultImage).join(TestResult).switch(TestResultImage).join(ProductTestStep)\
            .where((ProductTestStep.section == 2) &\
             ((TestResultStepRegion.byteIndex == (73 / 10)) | (TestResultStepRegion.byteIndex == (73 % 10))) & (TestResult.testDate >= dtStart) & (TestResult.testDate < dtEnd)\
                & (TestResultStepRegion.isOk == False)).count()
        for st in stepsData:
            if st['section'] == 2:
                st['count'] = st['count'] - abstractPlaceCount
                st['testName'] = 'Üst Kapak'
                break

        stepsData.append({
            'section': 0,
            'testName': 'Serigrafi',
            'count': abstractPlaceCount
        })

        result = {}
        result['ShiftData'] = shiftData
        result['EmployeeData'] = employeeData
        result['StepsData'] = stepsData
    except Exception as e:
        pass

    return result


# CONFIG CRUD
def getConfig():
    data = None
    try:
        rawData = ComConfig.select().first()
        data = model_to_dict(rawData)
    except:
        pass
    return data


def saveConfig(model):
    result = { 'Result': False, 'ErrorMessage': '', 'RecordId': 0 }
    try:
        dbObj:ComConfig = None
        try:
            dbObj = ComConfig.select().first()
        except Exception as ei:
            print(ei)
            pass

        if not dbObj:
            dbObj = ComConfig()

        dbObj.robotIp = model['robotIp']
        dbObj.robotPort = model['robotPort']
        dbObj.cameraIp = model['cameraIp']
        dbObj.cameraPort = model['cameraPort']
        dbObj.rbFromSafetyHome = model['rbFromSafetyHome']
        dbObj.rbToMasterJob = model['rbToMasterJob']
        dbObj.rbToSafetyHome = model['rbToSafetyHome']
        dbObj.valfPrm = model['valfPrm']
        dbObj.isFullPrm = model['isFullPrm']
        dbObj.testWithVacuum = model['testWithVacuum']

        dbObj.save()
        result['Result'] = True
    except Exception as e:
        print(e)

    return result


# POCO CLASSES
class BaseModel(Model):
    class Meta:
        database = db


class Product(BaseModel):
    id = AutoField()
    productNo = CharField(null=False)
    productName = CharField(null=False)
    gridWidth = IntegerField(null=True)
    gridHeight = IntegerField(null=True)
    isActive = BooleanField()
    imagePath = CharField(null=True)


class Employee(BaseModel):
    id = AutoField()
    employeeCode = CharField(null=False)
    employeeName = CharField(null=False)
    isActive = BooleanField()


class Shift(BaseModel):
    id = AutoField()
    shiftCode = CharField(null=False)
    startTime = TimeField()
    endTime = TimeField()
    isActive = BooleanField()


class ProductCamRecipe(BaseModel):
    id = AutoField()
    recipeCode = CharField(null=False)
    rbToRecipeStarted = CharField(null=True)
    rbFromReadyToStart = CharField(null=True)
    rbToStartScanning = CharField(null=True)
    rbFromScanningFinished = CharField(null=True)
    camResultByteIndex = IntegerField(null=True)
    orderNo = IntegerField()
    product = ForeignKeyField(Product, backref='camRecipes')
    startDelay = IntegerField(null=True)
    camResultFormat = CharField(null=True)
    imageDir = CharField(null=True)


class ProductSection(BaseModel):
    id = AutoField()
    sectionName = CharField(null=False)
    orderNo = IntegerField(null=True)
    posX = IntegerField()
    posY = IntegerField()
    sectionWidth = IntegerField()
    sectionHeight = IntegerField()
    areaNo = IntegerField()
    areaInfo = CharField(null=True)
    product = ForeignKeyField(Product, backref='sections')
    productCamRecipe = ForeignKeyField(ProductCamRecipe, backref='sections', null=True)


class ProductSectionRegion(BaseModel):
    id = AutoField()
    regionName = CharField(null=True)
    byteIndex = IntegerField(null=True)
    posX = IntegerField(null=True)
    posY = IntegerField(null=True)
    width = IntegerField(null=True)
    height = IntegerField(null=True)
    section = ForeignKeyField(ProductSection, null=True)


class ProductTestStep(BaseModel):
    id = AutoField()
    testName = CharField(null=False)
    orderNo = IntegerField()
    product = ForeignKeyField(Product, backref='steps')
    section = ForeignKeyField(ProductSection, backref='steps', null = True)
    productCamRecipe = ForeignKeyField(ProductCamRecipe, backref='steps', null = True)
    isActive = BooleanField()


class TestResult(BaseModel):
    id = AutoField()
    testDate = DateTimeField()
    product = ForeignKeyField(Product, backref='results')
    barcode = CharField(null=True)
    section = ForeignKeyField(ProductSection, backref='results', null=True)
    step = ForeignKeyField(ProductTestStep, backref='results', null=True)
    shift = ForeignKeyField(Shift, null=True)
    employee = ForeignKeyField(Employee, null=True)
    isOk = BooleanField(null=True)


class TestResultImage(BaseModel):
    id = AutoField()
    imagePath = CharField(null=True)
    stepResult = BooleanField(null=True)
    step = ForeignKeyField(ProductTestStep, backref='resultImages', null=True)
    section = ForeignKeyField(ProductSection, backref='resultImages', null=True)
    testResult = ForeignKeyField(TestResult, backref='resultImages', null=True)


class TestResultStepRegion(BaseModel):
    id = AutoField()
    byteIndex = IntegerField(null=True)
    isOk = BooleanField(null=True)
    testResultImage = ForeignKeyField(TestResultImage, null=True)
    productSectionRegion = ForeignKeyField(ProductSectionRegion, null=True)


class LiveResult(BaseModel):
    id = AutoField()
    step = ForeignKeyField(ProductTestStep, null=True)
    testStatus = IntegerField(null=True)
    faultCount = IntegerField(null=True)
    okCount = IntegerField(null=True)


class LiveProduction(BaseModel):
    id = AutoField()
    shift = ForeignKeyField(Shift, null=True)
    employee = ForeignKeyField(Employee, null=True)
    oee = FloatField(null=True)
    

class ComConfig(BaseModel):
    id = AutoField()
    robotIp = CharField(null=True)
    robotPort = IntegerField(null=True)
    cameraIp = CharField(null=True)
    cameraPort = IntegerField(null=True)
    valfPrm = CharField(null=True)
    isFullPrm = CharField(null=True)
    rbToSafetyHome = CharField(null=True)
    rbFromSafetyHome = CharField(null=True)
    rbToMasterJob = CharField(null=True)
    testWithVacuum = BooleanField(null=True)


class StepVariable(BaseModel):
    id = AutoField()
    step = ForeignKeyField(ProductTestStep, backref='variables', null=True)
    variableName = CharField(null=True)
    description = CharField(null=True)
    variableValue = IntegerField(null=True)


