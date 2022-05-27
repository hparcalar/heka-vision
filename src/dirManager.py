from os import listdir
from os.path import isfile, join, isdir, getmtime
from src.hkThread import HekaThread
from datetime import datetime
from time import sleep


class DirManager:
    def __init__(self, backend) -> None:
        self._backend = backend
        self._directories = []
        self._isRunning = False
        self._listeners = []


    def __raiseNewImageResult(self, dir, imagePath):
        self._backend.raiseNewImageResult(dir, imagePath)


    def __listenProcess(self, dir):
        threshDate = datetime.now()

        while self._isRunning == True:
            try:
                if isdir(dir):
                    subDirs = listdir(dir)
                    if len(subDirs) > 0:
                        latestTestDir = sorted(subDirs, key= lambda d: getmtime(dir + '/' + d), reverse=True)[0]
                        imageList = listdir(dir + '/' + latestTestDir)

                        if len(imageList) > 0:
                            latestImage = sorted(imageList, key= lambda d: getmtime(dir + '/' + latestTestDir + '/' + d), reverse=True)[0]
                            if latestImage:
                                fullPath = dir + '/' + latestTestDir + '/' + latestImage
                                if datetime.fromtimestamp(getmtime(fullPath)) > threshDate:
                                    self.__raiseNewImageResult(dir, fullPath)
                                    threshDate = datetime.now()
                            
            except:
                pass
            sleep(0.5)


    def stopListeners(self):
        self._isRunning = False
        try:
            for l in self._listeners:
                l.stop()
        except:
            pass
        self._listeners.clear()

    
    def setDirectories(self, dirList):
        self.stopListeners()
        self._directories = dirList


    def startListeners(self):
        self._isRunning = True
        for d in self._directories:
            lThread = HekaThread(target=self.__listenProcess, args=(d,))
            self._listeners.append(lThread)
            lThread.start()
            
