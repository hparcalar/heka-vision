import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtQuick.Dialogs 1.1
import QtGraphicalEffects 1.0

Popup {
    id: popupContainer
    modal: true
    dim: true
    Overlay.modal: Rectangle {
        color: "#aacfdbe7"
    }

    anchors.centerIn: parent
    width: parent.width * 0.6
    height: parent.height * 0.6

    enter: Transition {
        NumberAnimation { properties: "opacity"; from: 0; to: 1 }
    }

    exit: Transition {
        NumberAnimation { properties: "opacity"; from: 1; to: 0 }
    }

    property int recordId: 0

    Component.onCompleted: function(){
        bindModel();
    }

    // TIMER DELAY STRUCTURE
    Timer {
        id: timer
    }

    function delay(delayTime, cb) {
        timer.interval = delayTime;
        timer.repeat = false;
        timer.triggered.connect(cb);
        timer.start();
    }
    // END TIMER DELAY STRUCTURE

    function bindModel(){
        if (recordId > 0){
            backend.requestShiftInfo(recordId);
        }
        else{
            txtShiftCode.text = '';
            
        }
    }

    function saveModel(){
        waitingIcon.visible = true;
        delay(200, function(){
            backend.saveShift(JSON.stringify({
                id: recordId,
                shiftCode: txtShiftCode.text,
                startTime: txtStartTime.text,
                endTime: txtEndTime.text,
                isActive: true,
            }));
        });
    }

    function deleteModel(){
        waitingIcon.visible = true;
        delay(200, function(){
            backend.deleteShift(recordId);
        });
    }

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onGetShiftInfo(shiftInfo){
            const data = JSON.parse(shiftInfo);
            if (data){
                txtShiftCode.text = data.shiftCode;
                txtStartTime.text = data.startTime;
                txtEndTime.text = data.endTime;
            }
        }

        function onSaveShiftFinished(saveResult){
            waitingIcon.visible = false;
            var resultData = JSON.parse(saveResult);
            if (resultData){
                if (resultData.Result){
                    recordId = resultData.RecordId
                    backend.broadcastShiftListRefresh();
                }
            }
        }

        function onDeleteShiftFinished(saveResult){
            waitingIcon.visible = false;
            var resultData = JSON.parse(saveResult);
            if (resultData){
                if (resultData.Result){
                    backend.broadcastShiftListRefresh();
                    popupContainer.close();
                }
                else{

                }
            }
        }
    }

    MessageDialog {
        id: msgBoxConfirmDelete
        visible: false
        icon: StandardIcon.Question
        standardButtons: StandardButton.Yes | StandardButton.No
        title: "Uyarı"
        text: "Bu vardiyayı silmek istediğinizden emin misiniz?"
        onYes: {
            visible = false;
            deleteModel();
        }
    }

    ColumnLayout{
        anchors.fill: parent

        // TITLE BAR
        Rectangle{
            Layout.preferredHeight: 50
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            color: "#326195"
            radius: 5
            border.color: "#333"
            border.width: 1

            RowLayout{
                anchors.fill: parent

                // APPLICATION TITLE
                Rectangle{
                    Layout.fillWidth: true
                    height:50
                    color: "transparent"
                    
                    Text {
                        width: parent.width
                        anchors.top: parent.top
                        horizontalAlignment: Qt.AlignHCenter
                        color:"#fefefe"
                        padding: 10
                        font.pixelSize: 24
                        font.bold: true
                        text: "Vardiya Tanımı"
                    }

                    RowLayout{
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        anchors.rightMargin: 5

                        // WAIT FOR PROCESS ICON
                        Button{
                            id: waitingIcon
                            Layout.preferredWidth: 49
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignRight
                            visible: false
                            padding: 5
                            background: Rectangle {
                                color: "#fefefe"
                                border.width: 1
                                border.color: "#333"
                                radius: 4
                            }
                            Image {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 5
                                anchors.leftMargin: 10
                                sourceSize.width: 50
                                sourceSize.height: 30
                                fillMode: Image.Stretch
                                source: "../assets/waiting.png"
                            }
                        }
                        
                        // SAVE BUTTON
                        Button{
                            onClicked: function(){
                                saveModel();
                            }
                            Layout.preferredWidth: 49
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignRight
                            padding: 5
                            background: Rectangle {
                                color: "#24d151"
                                border.width: 1
                                border.color: "#333"
                                radius: 4
                            }
                            Image {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 5
                                anchors.leftMargin: 10
                                sourceSize.width: 50
                                sourceSize.height: 30
                                fillMode: Image.Stretch
                                source: "../assets/save.png"
                            }
                        }

                        // DELETE BUTTON
                        Button{
                            onClicked: function(){
                                msgBoxConfirmDelete.visible = true;
                            }
                            Layout.preferredWidth: 49
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignRight
                            padding: 5
                            background: Rectangle {
                                color: "#e6210b"
                                border.width: 1
                                border.color: "#333"
                                radius: 4
                            }
                            Image {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 5
                                anchors.leftMargin: 10
                                sourceSize.width: 50
                                sourceSize.height: 30
                                fillMode: Image.Stretch
                                source: "../assets/delete.png"
                            }
                        }

                        // CLOSE BUTTON
                        Button{
                            onClicked: function(){
                                popupContainer.close();
                            }
                            Layout.preferredWidth: 49
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignRight
                            padding: 5
                            background: Rectangle {
                                color: "#fefefe"
                                border.width: 1
                                border.color: "#333"
                                radius: 4
                            }
                            Image {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 5
                                anchors.leftMargin: 10
                                sourceSize.width: 50
                                sourceSize.height: 30
                                fillMode: Image.Stretch
                                source: "../assets/close.png"
                            }
                        }
                    }
                }
            }
        }

        // FORM CONTENT
        Rectangle{
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 10
            color: "transparent"

            RowLayout{
                anchors.fill: parent

                Rectangle{
                    Layout.preferredWidth: parent.width * 0.5
                    Layout.fillHeight: true
                    color: "transparent"

                    ColumnLayout{
                        anchors.fill: parent

                        // SHIFT CODE FIELD
                        Rectangle{
                            Layout.preferredHeight: 75
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            Layout.margins: 10
                            color: "transparent"

                            ColumnLayout{
                                anchors.fill: parent

                                Label{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignTop
                                    horizontalAlignment: Text.AlignLeft
                                    text:'Vardiya Kodu'
                                    font.pixelSize: 16
                                }

                                TextField {
                                    id: txtShiftCode
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    onFocusChanged: function(){
                                            backend.requestOsk(focus);
                                        }
                                    font.pixelSize: 16
                                    padding: 10
                                    background: Rectangle {
                                        radius: 5
                                        border.color: parent.focus ? "#326195" : "#888"
                                        border.width: 1
                                        color: parent.focus ? "#efefef" : "transparent"
                                    }
                                }
                            }
                        }

                        // VIEW BUFFER RECT
                        Rectangle{
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                        }
                    }
                }

                Rectangle{
                    Layout.preferredWidth: parent.width * 0.5
                    Layout.fillHeight: true
                    color: "transparent"

                    ColumnLayout{
                        anchors.fill: parent

                        // START TIME FIELD
                        Rectangle{
                            Layout.preferredHeight: 75
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            Layout.margins: 10
                            color: "transparent"

                            ColumnLayout{
                                anchors.fill: parent

                                Label{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignTop
                                    horizontalAlignment: Text.AlignLeft
                                    text:'Başlangıç Saati'
                                    font.pixelSize: 16
                                }

                                TextField {
                                    id: txtStartTime
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    onFocusChanged: function(){
                                            backend.requestOsk(focus);
                                        }
                                    inputMask: '00:00'
                                    font.pixelSize: 16
                                    padding: 10
                                    background: Rectangle {
                                        radius: 5
                                        border.color: parent.focus ? "#326195" : "#888"
                                        border.width: 1
                                        color: parent.focus ? "#efefef" : "transparent"
                                    }
                                }
                            }
                        }

                         // END TIME FIELD
                        Rectangle{
                            Layout.preferredHeight: 75
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            Layout.margins: 10
                            color: "transparent"

                            ColumnLayout{
                                anchors.fill: parent

                                Label{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignTop
                                    horizontalAlignment: Text.AlignLeft
                                    text:'Bitiş Saati'
                                    font.pixelSize: 16
                                }

                                TextField {
                                    id: txtEndTime
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    onFocusChanged: function(){
                                            backend.requestOsk(focus);
                                        }
                                    inputMask: '00:00'
                                    font.pixelSize: 16
                                    padding: 10
                                    background: Rectangle {
                                        radius: 5
                                        border.color: parent.focus ? "#326195" : "#888"
                                        border.width: 1
                                        color: parent.focus ? "#efefef" : "transparent"
                                    }
                                }
                            }
                        }

                        // VIEW BUFFER RECT
                        Rectangle{
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                        }
                    }
                }
            }
        }
    }
}

