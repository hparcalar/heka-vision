from os import listdir
from os.path import isfile, join, isdir, getmtime, getctime

from src.hkThread import HekaThread
from datetime import datetime, timedelta
from time import sleep
from PIL import Image

class DirManager:
    def __init__(self, backend) -> None:
        self._backend = backend
        self._directories = []
        self._threshDates = []
        self._recipes = []
        self._isRunning = False
        self._listeners = []
        self._histories = []


    def __raiseNewImageResult(self, dir, imagePath, recipe):
        self._backend.raiseNewImageResult(dir, imagePath, recipe)


    def __listenProcess(self, dir):
        # threshDate = datetime.now()

        while self._isRunning == True:
            try:
                if isdir(dir):
                    subDirs = listdir(dir)
                    if len(subDirs) > 0:
                        latestTestDir = sorted(subDirs, key= lambda d: getctime(dir + '/' + d), reverse=True)[0]
                        imageList = list(filter(lambda x: not ("capture" in x), listdir(dir + '/' + latestTestDir)))

                        if len(imageList) > 0:
                            latestImage = sorted(imageList, key= lambda d: getctime(dir + '/' + latestTestDir + '/' + d), reverse=True)[0]
                            if latestImage:
                                dirIndex = self._directories.index(dir)
                                histArr = self._histories[dirIndex]

                                fullPath = dir + '/' + latestTestDir + '/' + latestImage
                                if datetime.fromtimestamp(getctime(fullPath)) > self._threshDates[dirIndex] and not fullPath in histArr:
                                    sleep(2)
                                    histArr.append(fullPath)
                                    if len(histArr) >= 10:
                                        histArr.pop(0)
                                    
                                    try:
                                        im = Image.open(fullPath)
                                        im=im.rotate(90, expand=True)
                                        im.save(fullPath)
                                    except Exception as e:
                                        # print('Rotate error: ')
                                        # print(e)
                                        pass

                                    self._threshDates[dirIndex] = datetime.now()

                                    #threshDate = datetime.now()
                                    self.__raiseNewImageResult(dir, fullPath, self._recipes[dirIndex])
                            
            except:
                pass
            sleep(0.5)


    def stopListeners(self):
        self._isRunning = False
       
        try:
            for l in self._listeners:
                l.stop()
        except Exception as e:
            print(e)
            pass

        # self._listeners.clear()
        # self._directories.clear()
        # self._recipes.clear()

    
    def setDirectories(self, dirList):
        self.stopListeners()
        self._directories = dirList
        self._threshDates = []
        dtNow = datetime.now()
        for d in self._directories:
            self._threshDates.append(dtNow)


    def setRecipes(self, recipeList):
        self._recipes = recipeList


    def startListeners(self):
        self._isRunning = True

        try:
            self._histories.clear()
        except:
            pass

        try:
            self._listeners.clear()
        except:
            pass
        
        for d in self._directories:
            lThread = HekaThread(target=self.__listenProcess, args=(d,))
            self._listeners.append(lThread)
            self._histories.append([])
            lThread.start()
            

    def getCaptureImage(self, camImage: str):
        try:
            capturePath = '/home/heka/FtpContent/xg/capture'
            pathArr = camImage.split('/')
            camImageName = pathArr[len(pathArr) - 1]
            print('CAM IMAGE:')
            print(camImageName)

            camImageParts = camImageName.split('_')
            camImageTime = camImageParts[0] + '_' + camImageParts[1]
            print('CAM IMAGE TIME:')
            print(camImageTime)

            captureList = listdir(capturePath)
            properCaptures = list(filter(lambda x: (camImageTime + '.bmp') < x, captureList))

            print('PROPER CAPTURES')
            foundCapture = sorted(properCaptures, key= lambda x: x, reverse=False)[0]

            print(foundCapture)
            
            if foundCapture:
                return capturePath + '/' + foundCapture

            # imageDir = camImage.replace(camImageName, '')
            # if imageDir and isdir(imageDir):
            #     fnames = listdir(imageDir)

            #     uniqueName = camImageName[0:camImageName.index('&') + 1]

            #     foundCaptureList = list(filter(lambda x: uniqueName in x and "capture" in x, fnames))
            #     if foundCaptureList and len(foundCaptureList) > 0:
            #         foundCapture = foundCaptureList[0]
            #         return imageDir + '/' + foundCapture
        except Exception as e:
            print(e)
            pass

        return None