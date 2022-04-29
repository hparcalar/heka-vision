from peewee import *
import datetime


db = SqliteDatabase('data/heka.db')


def create_tables():
    with db:
        db.create_tables([Product, Employee, Shift, 
            ProductSection, ProductSectionPart, ProductTestStep, 
            TestResult, LiveResult, LiveProduction])


class BaseModel(Model):
    class Meta:
        database = db


class Product(BaseModel):
    id = AutoField()
    productNo = CharField(null=False)
    productName = CharField(null=False)
    isActive = BooleanField()
    imagePath = CharField()


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


class ProductSection(BaseModel):
    id = AutoField()
    sectionName = CharField(null=False)
    orderNo = IntegerField()
    posX = IntegerField()
    posY = IntegerField()
    areaInfo = CharField()
    product = ForeignKeyField(Product, backref='sections')


class ProductSectionPart(BaseModel):
    id = AutoField()
    partName = CharField()
    orderNo = IntegerField()
    imagePath = CharField()
    product = ForeignKeyField(Product, backref='parts')
    section = ForeignKeyField(ProductSection, backref='parts')


class ProductTestStep(BaseModel):
    id = AutoField()
    testName = CharField(null=False)
    orderNo = IntegerField()
    product = ForeignKeyField(Product, backref='steps')
    section = ForeignKeyField(ProductSection, backref='steps')
    part = ForeignKeyField(ProductSectionPart, backref='steps')
    isActive = BooleanField()


class TestResult(BaseModel):
    id = AutoField()
    testDate = DateTimeField()
    product = ForeignKeyField(Product, backref='results')
    section = ForeignKeyField(ProductSection, backref='results')
    part = ForeignKeyField(ProductSectionPart, backref='results')
    step = ForeignKeyField(ProductTestStep, backref='results')
    shift = ForeignKeyField(Shift)
    employee = ForeignKeyField(Employee)
    isOk = BooleanField()


class LiveResult(BaseModel):
    id = AutoField()
    step = ForeignKeyField(ProductTestStep)
    testStatus = IntegerField()
    faultCount = IntegerField()
    okCount = IntegerField()


class LiveProduction(BaseModel):
    id = AutoField()
    shift = ForeignKeyField(Shift)
    employee = ForeignKeyField(Employee)
    oee = FloatField()
    