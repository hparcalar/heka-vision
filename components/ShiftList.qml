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

    property variant shiftList: []

    anchors.centerIn: parent
    width: parent.width * 0.8
    height: parent.height * 0.8

    enter: Transition {
        NumberAnimation { properties: "opacity"; from: 0; to: 1 }
    }

    exit: Transition {
        NumberAnimation { properties: "opacity"; from: 1; to: 0 }
    }

    Component.onCompleted: function(){
        bindModel();
    }

    function bindModel(){
        backend.requestShiftList();
    }

    function filterShift(){
        const filterRe = new RegExp(txtSearchShift.text, 'i');
        const filteredList = shiftList.filter(d => 
            d.shiftCode.match(filterRe)
        );
        rptShifts.model = filteredList;
    }

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onGetShiftList(data){
            var shifts = JSON.parse(data);
            if (shifts){
                rptShifts.model = shifts;
                shiftList = shifts;
            }
            filterShift();
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
                        text: "Vardiya Seçimi"
                    }

                    RowLayout{
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        anchors.rightMargin: 5

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

            ColumnLayout{
                anchors.fill: parent

                // FILTER & BUTTONS
                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.alignment: Qt.AlignTop
                    color: "transparent"

                    RowLayout{
                        anchors.fill: parent

                        TextField {
                            id: txtSearchShift
                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredWidth: parent.width * 0.6
                            
                            font.pixelSize: 24
                            placeholderText: qsTr("Arama")
                            onTextChanged: function(){
                                filterShift();
                            }
                        }
                    }
                }

                // TABLE HEADER
                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.alignment: Qt.AlignTop
                    color: "#dfdfdf"
                    border.color: "#888"
                    border.width: 1

                    RowLayout{
                        anchors.fill: parent
                        spacing: 0

                        Rectangle{
                            Layout.preferredWidth: parent.width * 0.4
                            Layout.fillHeight: true
                            color: "transparent"

                            Text {
                                width: parent.width
                                height: parent.height
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                color:"#333"
                                padding: 2
                                leftPadding: 10
                                font.pixelSize: 18
                                font.underline: true
                                font.bold: true
                                text: "Vardiya Kodu"
                            }
                        }

                        Rectangle{
                            Layout.preferredWidth: parent.width * 0.3
                            Layout.fillHeight: true
                            color: "transparent"

                            Text {
                                width: parent.width
                                height: parent.height
                                horizontalAlignment: Text.Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color:"#333"
                                padding: 2
                                leftPadding: 10
                                font.pixelSize: 18
                                font.underline: true
                                font.bold: true
                                text: "Başlangıç"
                            }
                        }

                        Rectangle{
                            Layout.preferredWidth: parent.width * 0.3
                            Layout.fillHeight: true
                            color: "transparent"

                            Text {
                                width: parent.width
                                height: parent.height
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color:"#333"
                                padding: 2
                                font.pixelSize: 18
                                font.underline: true
                                font.bold: true
                                text: "Bitiş"
                            }
                        }
                    }
                }

                // TABLE CONTENT
                Rectangle{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    ScrollView{
                        anchors.fill: parent
                        spacing: 0

                        ColumnLayout{
                            anchors.fill:parent
                            spacing: 1
                            Repeater{
                                id: rptShifts

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    Layout.alignment: Qt.AlignTop
                                    color: "#efefef"

                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: function(){
                                            backend.broadcastShiftSelected(modelData.id);
                                            popupContainer.close();
                                        }
                                    }
                                    
                                    RowLayout{
                                        anchors.fill: parent
                                        spacing: 0

                                        LinearGradient {
                                            Layout.preferredWidth: parent.width * 0.4
                                            Layout.fillHeight: true
                                            start: Qt.point(0, 0)
                                            end: Qt.point(width, 0)
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: "#326195" }
                                                GradientStop { position: 1.0; color: "#efefef" }
                                            }

                                            Text {
                                                width: parent.width
                                                height: parent.height
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignVCenter
                                                color:"#fff"
                                                padding: 2
                                                leftPadding: 10
                                                font.pixelSize: 16
                                                font.bold: true
                                                text: modelData.shiftCode
                                            }
                                        }

                                        Rectangle{
                                            Layout.preferredWidth: parent.width * 0.3
                                            Layout.fillHeight: true
                                            color: "transparent"

                                            Text {
                                                width: parent.width
                                                height: parent.height
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                color:"#333"
                                                padding: 2
                                                font.pixelSize: 16
                                                text: modelData.startTime
                                            }
                                        }

                                        Rectangle{
                                            Layout.preferredWidth: parent.width * 0.3
                                            Layout.fillHeight: true
                                            color: "transparent"

                                            Text {
                                                width: parent.width
                                                height: parent.height
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                color:"#333"
                                                padding: 2
                                                font.pixelSize: 16
                                                text: modelData.endTime
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

