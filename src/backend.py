import os
from pathlib import Path
from random import sample
import sys
import json
from time import sleep
from PySide2.QtCore import QObject, Slot, Signal
from threading import Thread

from numpy import true_divide

class BackendManager(QObject):
    def __init__(self):
        QObject.__init__(self)

    #SIGNALS
    showSettings = Signal()
    showTestView = Signal()
    getSections = Signal(str)
    getState = Signal(str)

    #SLOTS
    @Slot()
    def requestShowSettings(self):
        self.showSettings.emit()

    @Slot()
    def requestShowTest(self):
        self.showTestView.emit()

    @Slot(int)
    def requestSections(self, productId):
        sampleData = [
            {
                "Label": "1",
                "PosX": 100,
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

