import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0
import QtQuick.Extras 1.4

Item{
    property string sectionList

    // ON LOAD EVENT
    Component.onCompleted: function(){
        drawParts();
        requestSections();
        requestState();
    }

    function drawParts(){
        const stdImage = '../assets/climate-parts.jpeg';
        const partCategories = [
            { partName: 'Serigrafi', partImageLeft: stdImage, partImageRight: stdImage },
            { partName: 'Kapak', partImageLeft: stdImage, partImageRight: stdImage },
            { partName: 'Yan Gövde', partImageLeft: stdImage, partImageRight: stdImage },
            { partName: 'Gövde Ön', partImageLeft: stdImage, partImageRight: stdImage },
            { partName: 'İç Gövde', partImageLeft: stdImage, partImageRight: stdImage },
        ];

        for (var i = 0; i < partCategories.length; i++){
            var partObj = partCategories[i];

            cmpPartCategory.createObject(partsContainer, {
                    partName: partObj.partName,
                    partImageLeft: partObj.partImageLeft,
                    partImageRight: partObj.partImageRight,
                });
        }
    }

    function openSettings(){
        backend.requestShowSettings();
    }

    function requestSections(){
        backend.requestSections(1);
    }

    function requestState(){
        backend.requestState();
    }

    function drawState(stateData){
        if (testDataContainer.children.length > 0){
            for(var i = testDataContainer.children.length; i > 0 ; i--) {
                testDataContainer.children[i-1].destroy()
            }
        }

        if (stateData && stateData.length > 0){
            stateData.forEach(st => {
                cmpTestData.createObject(testDataContainer, {
                    controlSection: st.Section,
                    controlStatus: st.Status,
                    faultCount: st.FaultCount,
                });
            });
        }
    }

    function changeShift(){}

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onGetSections(sectionData){
            sectionList = sectionData;
            canvasProduct.requestPaint();
        }

        function onGetState(stateData){
            drawState(JSON.parse(stateData));
        }
    }

    // DYNAMIC COMPONENTS
    Component{
        id: cmpPartCategory

        Rectangle{
            property string partName
            property string partImageLeft
            property string partImageRight

            color:"transparent"
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height / 5 - 20
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                anchors.fill: parent

                // PART NAME
                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height / 3 - 20
                    color: "#326195"
                    radius:5

                    Text {
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color:"#FFFFFF"
                        padding: 3
                        font.pixelSize: 18
                        font.bold: true
                        text: partName
                    }
                }

                // PART IMAGES
                Rectangle{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    RowLayout{
                        anchors.fill: parent

                        Image {
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width / 2
                            sourceSize.width: parent.width / 2
                            sourceSize.height: parent.height
                            fillMode: Image.PreserveAspectFit
                            source: partImageLeft
                        }

                        Image {
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width / 2
                            sourceSize.width: parent.width / 2
                            sourceSize.height: parent.height
                            fillMode: Image.PreserveAspectFit
                            source: partImageRight
                        }
                    }
                }
            }
        }
    }

    Component{
        id: cmpTestData

        Rectangle{
            property string controlSection: ""
            property bool controlStatus: false
            property int faultCount: 0

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

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
                        GradientStop { position: 1.0; color: "#c8cacc" }
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
                        text: controlSection
                    }
                }

                Rectangle{
                    Layout.preferredWidth: parent.width * 0.3
                    Layout.fillHeight: true
                    color: "transparent"

                    Image {
                        anchors.centerIn: parent
                        sourceSize.width: 50
                        sourceSize.height: parent.height - 5
                        fillMode: Image.Stretch
                        source: controlStatus ? "../assets/ok.png" : "../assets/error.png"
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
                        font.bold: false
                        text: faultCount.toString()
                    }
                }
            }
        }
    }

    // VIEW LAYOUT
    Rectangle{
        id: testRect
        anchors.fill: parent
        color: "#c8cacc"

        RowLayout{
            anchors.fill: parent

            // PARTS CONTAINER
            Rectangle{
                Layout.preferredWidth: parent.width / 3
                Layout.fillHeight: true
                Layout.leftMargin: 5
                color: "transparent"

                ColumnLayout{
                    id: partsContainer
                    anchors.fill: parent
                    spacing:0
                }
            }

            // TEST STATUS CONTAINER
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: 5
                color: "transparent"

                ColumnLayout{
                    anchors.fill: parent

                    // FIRST ROW (PRODUCT INFORMATION AND BUTTONS)
                    Rectangle{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        Layout.alignment: Qt.AlignTop
                        color: "transparent"
                        
                        RowLayout{
                            anchors.fill: parent

                            // PRODUCT INFORMATION
                            Rectangle{
                                Layout.preferredWidth: parent.width / 2
                                Layout.fillHeight: true
                                color: "transparent"

                                ColumnLayout{
                                    anchors.fill: parent

                                    Text {
                                        id: txtProductCode
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        color:"#326195"
                                        padding: 2
                                        font.pixelSize: 32
                                        // style: Text.Outline
                                        // styleColor:'black'
                                        font.bold: true
                                        text: "Ürün Kodu: DK084614"
                                    }

                                    Text {
                                        id: txtOperatorName
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        color:"#333"
                                        padding: 2
                                        font.pixelSize: 24
                                        // style: Text.Outline
                                        // styleColor:'black'
                                        font.bold: false
                                        text: "Operatör: Yusuf SARI"
                                    }

                                    Text {
                                        id: txtShiftName
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        color:"#333"
                                        padding: 2
                                        font.pixelSize: 24
                                        // style: Text.Outline
                                        // styleColor:'black'
                                        font.bold: false
                                        text: "Vardiya: A"
                                    }
                                }
                            }

                            // BUTTONS
                            Rectangle{
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"

                                Flow{
                                    anchors.fill:parent
                                    spacing:5
                                    layoutDirection: Qt.RightToLeft

                                    Button{
                                        text: "Ayarlar"
                                        onClicked: openSettings()
                                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                        id:btnSettings
                                        font.pixelSize: 18
                                        font.bold: true
                                        padding: 10
                                        leftPadding: 50
                                        palette.buttonText: "#333"
                                        background: Rectangle {
                                            border.width: btnSettings.activeFocus ? 2 : 1
                                            border.color: "#333"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnSettings.pressed ? "#AAA" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnSettings.pressed ? "#dedede" : "#AAA" }
                                            }
                                        }

                                        Image {
                                            anchors.top: btnSettings.top
                                            anchors.left: btnSettings.left
                                            anchors.topMargin: 5
                                            anchors.leftMargin: 10
                                            sourceSize.width: 50
                                            sourceSize.height: 30
                                            fillMode: Image.Stretch
                                            source: "../assets/settings.png"
                                        }
                                    }

                                    Button{
                                        text: "Vardiya Değiştir"
                                        onClicked: changeShift()
                                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                        id:btnChangeShift
                                        font.pixelSize: 18
                                        font.bold: true
                                        padding: 10
                                        leftPadding: 50
                                        palette.buttonText: "#333"
                                        background: Rectangle {
                                            border.width: btnChangeShift.activeFocus ? 2 : 1
                                            border.color: "#326195"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnChangeShift.pressed ? "#326195" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnChangeShift.pressed ? "#dedede" : "#326195" }
                                            }
                                        }

                                        Image {
                                            anchors.top: btnChangeShift.top
                                            anchors.left: btnChangeShift.left
                                            anchors.topMargin: 5
                                            anchors.leftMargin: 10
                                            sourceSize.width: 50
                                            sourceSize.height: 30
                                            fillMode: Image.Stretch
                                            source: "../assets/exchange.png"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SECOND ROW (PRODUCT IMAGE)
                    Rectangle{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        Layout.alignment: Qt.AlignTop
                        color: "transparent"

                        Canvas {
                            id: canvasProduct
                            anchors.fill: parent
                            Component.onCompleted: {
                                loadImage("../assets/product.png")
                            }
                            onPaint: {
                                var ctx = getContext("2d");
                                const imgH = height - 10;
                                const imgW = width / 2 + 50;
                                const imgX = (width - imgW) / 2;
                                const imgY = 5;
                                ctx.drawImage('../assets/product.png', imgX, imgY, imgW, imgH);

                                if (sectionList != null && sectionList.length > 0){
                                    const sections = JSON.parse(sectionList);
                                    sections.forEach(sc => {
                                        ctx.beginPath();
                                        ctx.arc(imgX + sc.PosX, imgY + sc.PosY, 15, 0, 2 * Math.PI);
                                        ctx.stroke();
                                        
                                        ctx.fillStyle = "white";
                                        ctx.fill();

                                        ctx.fillStyle = "black";
                                        ctx.font = "bold 14px sans-serif";
                                        ctx.fillText(sc.Label, imgX + sc.PosX -5, imgY + sc.PosY + 5);
                                    });
                                }
                            }
                        }
                    }

                    // THIRD ROW (CHECK STATS)
                    Rectangle{
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignTop

                        color: "transparent"

                        ColumnLayout{
                            anchors.fill: parent
                            spacing: 0

                            // TABLE HEADER
                            Rectangle{
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
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
                                            text: "Kontrol Bölgesi"
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
                                            text: "Durum"
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
                                            text: "Toplam Hata"
                                        }
                                    }
                                }
                            }

                            // TABLE DATA CONTAINER
                            Rectangle{
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"

                                ColumnLayout{
                                    id: testDataContainer
                                    anchors.fill: parent
                                    spacing: 1
                                }
                            }
                        }
                    }

                    // FOURTH ROW (NETWORK STATS)
                    Rectangle{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 5

                        color: "transparent"
                        
                        RowLayout{
                            anchors.fill: parent
                            
                            Rectangle{
                                Layout.preferredWidth: parent.width * 0.4
                                Layout.fillHeight: true
                                color: "#dfdfdf"
                                border.color: "#888"
                                border.width: 1

                                ColumnLayout{
                                    anchors.fill: parent

                                    // ROBOT COMM INFO
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        RowLayout{
                                            anchors.fill: parent

                                            Text {
                                                Layout.preferredWidth: parent.width * 0.8
                                                horizontalAlignment: Text.AlignLeft
                                                color:"#326195"
                                                padding: 2
                                                leftPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: "Robot Haberleşme"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color:"#32a852"
                                                padding: 2
                                                rightPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: ": OK"
                                            }
                                        }
                                    }

                                    // CAMERA COMM INFO
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        RowLayout{
                                            anchors.fill: parent

                                            Text {
                                                Layout.preferredWidth: parent.width * 0.8
                                                horizontalAlignment: Text.AlignLeft
                                                color:"#326195"
                                                padding: 2
                                                leftPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: "Kamera Haberleşme"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color:"#32a852"
                                                padding: 2
                                                rightPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: ": OK"
                                            }
                                        }
                                    }

                                    // EMERGENCY CIRCUIT INFO
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        RowLayout{
                                            anchors.fill: parent

                                            Text {
                                                Layout.preferredWidth: parent.width * 0.8
                                                horizontalAlignment: Text.AlignLeft
                                                color:"#326195"
                                                padding: 2
                                                leftPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: "Acil Devresi"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color:"#32a852"
                                                padding: 2
                                                rightPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: ": OK"
                                            }
                                        }
                                    }

                                    // PRINTER STATUS INFO
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        RowLayout{
                                            anchors.fill: parent

                                            Text {
                                                Layout.preferredWidth: parent.width * 0.8
                                                horizontalAlignment: Text.AlignLeft
                                                color:"#326195"
                                                padding: 2
                                                leftPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: "Yazıcı"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color:"#32a852"
                                                padding: 2
                                                rightPadding: 10
                                                font.pixelSize: 24
                                                font.bold: true
                                                text: ": OK"
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle{
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#dfdfdf"
                                border.color: "#888"
                                border.width: 1

                                RowLayout{
                                    anchors.fill: parent

                                    Rectangle{
                                        Layout.preferredWidth: parent.width / 2
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            height: parent.height * 0.5
                                            anchors.topMargin: 5
                                            spacing:5

                                            // TOTAL TEST COUNT
                                            Rectangle{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 30
                                                color: "transparent"
                                                Layout.alignment: Qt.AlignTop

                                                RowLayout{
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    
                                                    Text {
                                                        Layout.preferredWidth: parent.width * 0.6
                                                        horizontalAlignment: Text.AlignLeft
                                                        color:"#326195"
                                                        padding: 2
                                                        leftPadding: 10
                                                        font.pixelSize: 24
                                                        font.bold: true
                                                        text: "Toplam Test"
                                                    }

                                                    Text {
                                                        Layout.preferredWidth: parent.width * 0.4
                                                        horizontalAlignment: Text.AlignLeft
                                                        color:"#333"
                                                        padding: 2
                                                        leftPadding: 10
                                                        font.pixelSize: 24
                                                        font.bold: true
                                                        text: ": 1300"
                                                    }
                                                }
                                            }           

                                            // TOTAL FAULT COUNT
                                            Rectangle{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 30
                                                color: "transparent"
                                                Layout.alignment: Qt.AlignTop

                                                RowLayout{
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    
                                                    Text {
                                                        Layout.preferredWidth: parent.width * 0.6
                                                        horizontalAlignment: Text.AlignLeft
                                                        color:"#326195"
                                                        padding: 2
                                                        leftPadding: 10
                                                        font.pixelSize: 24
                                                        font.bold: true
                                                        text: "Hatalı Adet"
                                                    }

                                                    Text {
                                                        Layout.preferredWidth: parent.width * 0.4
                                                        horizontalAlignment: Text.AlignLeft
                                                        color:"#c70c12"
                                                        padding: 2
                                                        leftPadding: 10
                                                        font.pixelSize: 24
                                                        font.bold: true
                                                        text: ": 10"
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // OEE STATUS
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"
                                        // Layout.topMargin: 20

                                        // CircularGauge {
                                        //     anchors.fill: parent
                                        //     style: CircularGaugeStyle {
                                        //         needle: Rectangle {
                                        //             y: outerRadius * 0.15
                                        //             implicitWidth: outerRadius * 0.03
                                        //             implicitHeight: outerRadius * 0.9
                                        //             antialiasing: true
                                        //             color: "#326195" //Qt.rgba(0.66, 0.3, 0, 1)
                                        //         }
                                        //         tickmark: Text {
                                        //             text: styleData.value

                                        //             Text {
                                        //                 anchors.horizontalCenter: parent.horizontalCenter
                                        //                 anchors.top: parent.bottom
                                        //                 text: styleData.index
                                        //                 color: "blue"
                                        //             }
                                        //         }
                                        //     }
                                        // }

                                        Gauge {
                                            id: oeeBar
                                            anchors.fill: parent
                                            orientation: Qt.Horizontal
                                            anchors.margins: 10

                                            value: 85
                                            Behavior on value {
                                                NumberAnimation {
                                                    duration: 1000
                                                }
                                            }

                                            style: GaugeStyle {
                                                valueBar: Rectangle {
                                                    implicitWidth: 50
                                                    color: "#326195"

                                                    Text{
                                                        anchors.bottom: parent.bottom
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 15
                                                        color: "white"
                                                        text: "OEE: " + oeeBar.value + "%"
                                                        font.bold: true
                                                        transform: Rotation { origin.x: 0; origin.y: 0; angle: -90}
                                                    }
                                                }
                                                background: Rectangle{
                                                    anchors.fill: parent
                                                    color: "#555"
                                                }
                                                minorTickmark: Item {
                                                    implicitWidth: 8
                                                    implicitHeight: 1

                                                    Rectangle {
                                                        color: "#333"
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 2
                                                        anchors.rightMargin: 4
                                                    }
                                                }

                                                tickmarkLabel: Text {
                                                    text: styleData.value

                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        anchors.top: parent.bottom
                                                        //text: styleData.index
                                                        color: "blue"
                                                    }
                                                }

                                                tickmark: Item {
                                                    implicitWidth: 18
                                                    implicitHeight: 1

                                                    Rectangle {
                                                        color: "#333"
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 3
                                                        anchors.rightMargin: 3
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
    }
}