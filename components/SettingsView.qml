import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0

Item{
    // ON LOAD EVENT
    Component.onCompleted: function(){
        
    }

    function openTestView(){
        backend.requestShowTest();
    }

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend
    }

    Rectangle{
        anchors.fill: parent
        color: "#c8cacc"

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            color:"#333"
            padding: 2
            font.pixelSize: 48
            style: Text.Outline
            styleColor:'#fff'
            font.bold: true
            text: "Settings Screen"
        }

        Button{
            text: "Tamam"
            onClicked: openTestView()
            anchors.leftMargin:10
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 10
            font.pixelSize: 36
            font.bold: true
            padding: 10
            leftPadding: 75
            palette.buttonText: "#fa6000"
        }
    }
}