# This Python file uses the following encoding: utf-8
import os
from pathlib import Path
import sys

from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, Slot, Signal
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtWidgets import QApplication
import PySide2.QtMultimedia
from src.backend import BackendManager

if __name__ == "__main__":
    os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    app.setOrganizationName("Heka Robotics")
    app.setOrganizationDomain("hekarobotics.com")
    app.setApplicationName("Heka Vision")

    backManager = BackendManager()
    engine.rootContext().setContextProperty("backend", backManager)

    engine.load(os.fspath(Path(__file__).resolve().parent / "main.qml"))

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec_())
