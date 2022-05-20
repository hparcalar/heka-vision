from datetime import time
from peewee import *
from playhouse.shortcuts import model_to_dict, dict_to_model


db = SqliteDatabase('data/heka.db')


def create_tables():
    with db:
        db.create_tables([Product, Employee, Shift, 
            ProductSection, ProductCamRecipe, ProductTestStep, 
            TestResult, TestResultImage,LiveResult, LiveProduction, ComConfig])

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
        rawData = Product.get(Product.id == productId)
        data = model_to_dict(rawData, backrefs = True)

        rawSections = ProductSection.select().join(Product).where(Product.id == productId).dicts()
        data['sections'] = list(rawSections)

        rawRecipes = ProductCamRecipe.select().join(Product).where(Product.id == productId).dicts()
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
            else:
                st['camRecipeId'] = None
        data['steps'] = list(listSteps)

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
                dbRecipe.camResultByteIndex = d['camResultByteIndex']
                dbRecipe.rbFromReadyToStart = d['rbFromReadyToStart']
                dbRecipe.rbFromScanningFinished = d['rbFromScanningFinished']
                dbRecipe.rbToRecipeStarted = d['rbToRecipeStarted']
                dbRecipe.rbToStartScanning = d['rbToStartScanning']
                dbRecipe.orderNo = 0
                dbRecipe.product = dbObj
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


# EMPLOYEE CRUD
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
        rawData = Employee.get(Employee.id == employeeId)
        data = model_to_dict(rawData, backrefs = True)
    except:
        pass
    return data


def getEmployeeByCard(cardNo):
    data = None
    try:
        rawData = Employee.get(Employee.employeeCode == cardNo)
        data = model_to_dict(rawData, backrefs = True)
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


# SHIFT CRUD
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
        rawData = Shift.get(Shift.id == shiftId)
        data = model_to_dict(rawData, backrefs = True)

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
    step = ForeignKeyField(ProductTestStep, backref='resultImages', null=True)
    section = ForeignKeyField(ProductSection, backref='resultImages', null=True)
    testResult = ForeignKeyField(TestResult, backref='resultImages', null=True)


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
