import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtMultimedia 5.12
import QtQuick.Dialogs 1.1
import "components"

ApplicationWindow {
    width: screen.desktopAvailableWidth
    height: screen.desktopAvailableHeight
    flags: Qt.WindowMaximized | Qt.Window
    visible: true
    title: qsTr("Klima Gövde-Kapak Kalite Sistemi")
    onClosing: function(){
        return true;
    }

    // COMPONENTS
    Component{
        id: cmpTestView
        TestView {
            
        }
    }

    Component{
        id: cmpSettingsView
        SettingsView {
            
        }
    }


    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onShowSettings(){
            contentLoader.replace(contentLoader.currentItem, cmpSettingsView);
            // contentLoader.sourceComponent = cmpSettingsView;
        }

        function onShowTestView(){
            contentLoader.replace(contentLoader.currentItem, cmpTestView);
            // contentLoader.sourceComponent = cmpTestView;
        }
    }

    // MAIN LAYOUT
    Rectangle{
        anchors.fill: parent
        color: "#c8cacc"

        ColumnLayout{
            anchors.fill:parent

            // TOP BAR
            Rectangle{
                Layout.preferredHeight: 100
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                color: "#326195"

                RowLayout{
                    anchors.fill: parent

                    // HEKA LOGO
                    Rectangle{
                        Layout.preferredWidth: (parent.width / 3) - 50
                        height:100
                        color: "transparent"
                        Image {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            sourceSize.width: parent.width - 10
                            sourceSize.height: 100
                            fillMode: Image.Stretch
                            source: "assets/heka-blue-bg.jpeg"
                        }
                    }

                    // APPLICATION TITLE
                    Rectangle{
                        Layout.preferredWidth: parent.width / 3
                        height:100
                        color: "transparent"
                        
                        Text {
                            width: parent.width
                            anchors.top: parent.top
                            anchors.topMargin: 20
                            color:"#fefefe"
                            padding: 10
                            font.pixelSize: 32
                            font.bold: true
                            text: "Klima Gövde-Kapak Kalite Sistemi"
                        }
                    }

                    // FACTORY LOGO
                    Rectangle{
                        Layout.preferredWidth: parent.width / 3
                        Layout.alignment: Qt.AlignRight
                        height:100
                        color: "transparent"
                        
                        Image {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            sourceSize.width: parent.width - 10
                            sourceSize.height: 80
                            fillMode: Image.Stretch
                            source: "assets/topdal.png"
                        }
                    }
                }
            }

            // CONTENT LOADER
            StackView {
                id: contentLoader
                initialItem: cmpTestView
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
            // Loader{
            //     id: contentLoader
            //     Layout.fillHeight: true
            //     Layout.fillWidth: true
            //     sourceComponent: cmpTestView
            // }
        }
    }
}