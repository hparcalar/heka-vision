import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtMultimedia 5.12
import QtQuick.Dialogs 1.1
import QtGraphicalEffects 1.0
import QtQuick.Extras 1.4
import "components"

ApplicationWindow {
    width: screen.desktopAvailableWidth
    height: screen.desktopAvailableHeight
    // visibility: Window.FullScreen
    flags: Qt.WindowMaximized | Qt.FramelessWindowHint //| Qt.Window
    visible: true
    title: qsTr("Klima Gövde-Kapak Kalite Sistemi")
    onClosing: function(){
        backend.appIsClosing();
        return true;
    }

    FontLoader { id: customFont; source:'assets/ttl.ttf' }

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
                        // Layout.preferredWidth: parent.width / 3
                        anchors.fill: parent
                        height:100
                        color: "transparent"
                        
                        Text {
                            font.family: customFont.name
                            width: parent.width
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            color:"#fefefe"
                            padding: 10
                            font.pixelSize: 26
                            font.bold: true
                            text: "KLİMA GÖVDE KALİTE SİSTEMİ"
                        }
                    }

                    // FACTORY LOGO
                    LinearGradient{
                        Layout.preferredWidth: parent.width / 3
                        Layout.alignment: Qt.AlignRight
                        height:100
                        // color: "transparent"
                        start: Qt.point(0, 0)
                        end: Qt.point(width - 100, 0)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#326195" }
                            GradientStop { position: 1.0; color: "#c8cacc" }
                        }
                        
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