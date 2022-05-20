import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0
import QtQuick.Extras 1.4

Item{
    id: testViewFormContainer

    property string sectionList
    property int loginState: 0

    property string silentCardNo: ""
    property date silentDate: new Date()
    property bool silentDateSet: false
    property double silentReadSeq: 1000.0

    property var activeProduct: new Object({ id: -1 })
    property var activeEmployee: new Object({ id: -1 })
    property var activeShift: new Object({ id: -1 })

    // LOGIN WARNING MESSAGE
    Timer {
        id: tmrCardRead
        interval: 300
        repeat: false
        running: false
        onTriggered: {
            if (silentReadSeq < 300 && silentCardNo)
            {
                if (silentCardNo.length > 2)
                    backend.requestEmployeeCard(silentCardNo);
                else{
                    silentDateSet = false;
                    silentCardNo = "";
                }
            }
        }
    }

    // ON LOAD EVENT
    Component.onCompleted: function(){
        requestProduct();
        requestState();
        popupCardRead.open();
    }

    function drawParts(){
        for(var i = partsContainer.children.length; i > 0 ; i--) {
            partsContainer.children[i-1].destroy()
        }

        if (activeProduct && activeProduct.sections){
            for (var i = 0; i < activeProduct.sections.length; i++){
                var partObj = activeProduct.sections[i];

                cmpPartCategory.createObject(partsContainer, {
                        partName: partObj.sectionName,
                        partImageLeft: null,
                        partImageRight: null,
                    });
            }
        }
    }

    function bindTestSteps(){
        if (testDataContainer.children.length > 0){
            for(var i = testDataContainer.children.length; i > 0 ; i--) {
                testDataContainer.children[i-1].destroy()
            }
        }

        if (activeProduct && activeProduct.steps){
            activeProduct.steps.sort((a,b) => a.orderNo - b.orderNo).forEach(st => {
                cmpTestData.createObject(testDataContainer, {
                    controlSection: st.testName,
                    controlStatus: true,
                    faultCount: 0,
                });
            });
        }
    }

    function openSettings(){
        popupAuth.open();
    }

    function requestState(){
        backend.requestState();
    }

    function requestProduct(){
        backend.requestProductInfo(activeProduct.id);
    }

    function clearIntersectedAreas(gridArr, area){
        const cluster = [];
        cluster.push({ x: area.posX, y: area.posY });
        
        for (let i = 0; i < area.sectionWidth * area.sectionHeight; i++) {
            cluster.push({ x: i % area.sectionWidth + area.posX, y: Math.floor(i / area.sectionWidth) + area.posY });
        }

        const foundShallows = gridArr.filter(d => d.isShallow == true && cluster.some(c => c.x == d.posX && c.y == d.posY));
        if (foundShallows){
            gridArr = gridArr.filter(item => !foundShallows.includes(item))
        }

        return gridArr;
    }

    function bindGridSchema(){
        try {
            var w = activeProduct.gridWidth;
            var h = activeProduct.gridHeight;

            if (!w || !h)
                return;

            var gridArr = [];

            for (let i = 0; i < w * h; i++) {
                gridArr.push({
                    areaNo: i + 1,
                    posX: (i % w),
                    posY: Math.floor(i  / w),
                    sectionWidth: 1,
                    sectionHeight: 1,
                    sectionName: '',
                    isShallow: true,
                });
            }

            if (activeProduct && activeProduct.sections){
                activeProduct.sections.forEach(d => {
                    const blockObj = {
                        areaNo: d.areaNo,
                        posX: d.posX,
                        posY: d.posY,
                        sectionWidth: d.sectionWidth,
                        sectionHeight: d.sectionHeight,
                        sectionName: d.sectionName,
                        isShallow: false,
                    };
                    gridArr = clearIntersectedAreas(gridArr, blockObj);
                    gridArr.push(blockObj);
                });
            }

            gridProduct.columns = w;
            gridProduct.rows = h;
            rptGridProduct.model = gridArr.sort((a,b) => (a.posY * w + a.posX) - (b.posY * w + b.posX));
        } 
        catch (error) {

        }
    }

    function bindProduct(){
        if (activeProduct){
            try {
                txtProductCode.text = 'Ürün : ' + activeProduct.productNo;
            } catch (error) {
                
            }
        }

        drawParts();
        bindTestSteps();
        bindGridSchema();
    }

    function showProductList(){
        var popup = cmpProductList.createObject(testViewFormContainer, {});
        popup.open();
    }

    function bindEmployee(){
        if (activeEmployee){
            txtOperatorName.text = 'Operatör: ' + activeEmployee.employeeName;
        }
    }

    function showEmployeeList(){
        var popup = cmpEmployeeList.createObject(testViewFormContainer, {});
        popup.open();
    }

    function bindShift(){
        if (activeShift){
            txtShiftCode.text = 'Vardiya: ' + activeShift.shiftCode;
        }
    }

    function showShiftist(){
        var popup = cmpShiftList.createObject(testViewFormContainer, {});
        popup.open();
    }

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onGetProductInfo(data){
            activeProduct = JSON.parse(data);
            if (activeProduct){
                if (activeProduct.sections)
                    activeProduct.sections = activeProduct.sections.sort((a,b) => a.orderNo - b.orderNo);
                
                bindProduct();
            }
            else{
                showProductList();
            }
        }

        function onEmployeeSelected(data){
            activeEmployee = JSON.parse(data);
            bindEmployee();
        }

        function onShiftSelected(data){
            activeShift = JSON.parse(data);
            bindShift();
        }

        function onProductSelected(data){
            activeProduct = JSON.parse(data);
            if (activeProduct.sections)
                activeProduct.sections = activeProduct.sections.sort((a,b) => a.orderNo - b.orderNo);

            bindProduct();
        }

        function onEmployeeCardRead(data){
            activeEmployee = JSON.parse(data);
            if (activeEmployee){
                popupCardRead.close();
                bindEmployee();
            }
            else{
                silentDateSet = false;
                silentCardNo = "";
                lblCardError.visible = true;
                txtCardNo.text = "";
            }
        }
    }

    // POPUPS
    Popup {
        id: popupAuth
        modal: true
        dim: true
        Overlay.modal: Rectangle {
            color: "#aacfdbe7"
        }

        anchors.centerIn: parent
        width: parent.width / 3
        height: 210

        enter: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1 }
        }

        exit: Transition {
            NumberAnimation { properties: "opacity"; from: 1; to: 0 }
        }

        onAboutToShow: function(){
            loginState = 0;
            lblLoginError.visible = false;
            txtLoginPassword.text = '';
        }

        onOpened: function(){
            txtLoginPassword.forceActiveFocus();
        }

        ColumnLayout{
            anchors.fill: parent

            Label{
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                horizontalAlignment: Text.AlignHCenter
                text:'Yönetici Girişi'
                font.bold: true
                font.pixelSize: 24
            }

            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout{
                    anchors.fill: parent

                    TextField {
                        id: txtLoginPassword
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        echoMode: TextInput.Password
                        Keys.onPressed: function(event){
                            if (event.key == Qt.Key_Enter){
                                if (txtLoginPassword.text == '8910'){
                                    if (loginState == 0){
                                        loginState = 1;
                                        popupAuth.close();
                                        backend.requestShowSettings();
                                    }
                                }
                                else{
                                    lblLoginError.visible = true;
                                }
                            }
                        }
                        font.pixelSize: 24
                        placeholderText: qsTr("Parolayı girin")
                    }

                    Label{
                        id: lblLoginError
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignTop
                        topPadding:5
                        visible: false
                        color: "red"
                        background: Rectangle{
                            anchors.fill: parent
                            anchors.bottomMargin: 10
                            color:"#22fa0202"
                            border.color: "red"
                            border.width: 1
                            radius: 5
                        }
                        horizontalAlignment: Text.AlignHCenter
                        text:'Hatalı parola girdiniz.'
                        font.bold: true
                        font.pixelSize: 18
                    }
                }
            }

            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.alignment: Qt.AlignBottom
                color: "transparent"

                RowLayout{
                    anchors.fill: parent

                    Button{
                        id: btnLoginCancel
                        onClicked: function(){
                            popupAuth.close();
                        }
                        text: "VAZGEÇ"
                        Layout.preferredWidth: parent.width * 0.5
                        Layout.fillHeight: true
                        font.pixelSize: 24
                        font.bold: true
                        padding: 5
                        leftPadding: 50
                        palette.buttonText: "#333"
                        background: Rectangle {
                            border.width: btnLoginCancel.activeFocus ? 2 : 1
                            border.color: "#333"
                            radius: 4
                            gradient: Gradient {
                                GradientStop { position: 0 ; color: btnLoginCancel.pressed ? "#AAA" : "#dedede" }
                                GradientStop { position: 1 ; color: btnLoginCancel.pressed ? "#dedede" : "#AAA" }
                            }
                        }

                        Image {
                            anchors.top: btnLoginCancel.top
                            anchors.left: btnLoginCancel.left
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            sourceSize.width: 50
                            sourceSize.height: 30
                            fillMode: Image.Stretch
                            source: "../assets/back.png"
                        }
                    }

                    Button{
                        id: btnLoginApply
                        text: "GİRİŞ"
                        onClicked: function(){
                            if (txtLoginPassword.text == '8910'){
                                popupAuth.close();
                                backend.requestShowSettings();
                            }
                            else{
                                lblLoginError.visible = true;
                            }
                        }
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.pixelSize: 24
                        font.bold: true
                        padding: 5
                        leftPadding: 50
                        palette.buttonText: "#333"
                        background: Rectangle {
                            border.width: btnLoginApply.activeFocus ? 2 : 1
                            border.color: "#326195"
                            radius: 4
                            gradient: Gradient {
                                GradientStop { position: 0 ; color: btnLoginApply.pressed ? "#326195" : "#dedede" }
                                GradientStop { position: 1 ; color: btnLoginApply.pressed ? "#dedede" : "#326195" }
                            }
                        }

                        Image {
                            anchors.top: btnLoginApply.top
                            anchors.left: btnLoginApply.left
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            sourceSize.width: 50
                            sourceSize.height: 30
                            fillMode: Image.Stretch
                            source: "../assets/login.png"
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: popupCardRead
        modal: true
        dim: true
        Overlay.modal: Rectangle {
            color: "#aacfdbe7"
        }

        anchors.centerIn: parent
        width: parent.width / 3
        height: 210

        enter: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1 }
        }

        exit: Transition {
            NumberAnimation { properties: "opacity"; from: 1; to: 0 }
        }

        onAboutToShow: function(){
            silentCardNo = "";
            silentDateSet = false;
            silentReadSeq = 0.0;

            lblCardError.visible = false;
            txtCardNo.text = '';
        }

        onOpened: function(){
            txtCardNo.forceActiveFocus();
        }

        ColumnLayout{
            anchors.fill: parent

            Label{
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                horizontalAlignment: Text.AlignHCenter
                text:'Personel Kartınızı Okutun'
                font.bold: true
                font.pixelSize: 24
            }

            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout{
                    anchors.fill: parent

                    TextField {
                        id: txtCardNo
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        echoMode: TextInput.Password
                        Keys.onPressed: function(event){
                            if (!silentDateSet){
                                silentDateSet = true;
                                silentDate = new Date();
                            }

                            const dtKey = new Date();
                            const diffMs = dtKey.getTime() - silentDate.getTime();

                            if (silentCardNo.length > 0)
                                silentReadSeq = (silentReadSeq + diffMs) / silentCardNo.length;

                            if (event.text)
                                silentCardNo += event.text;

                            silentDate = dtKey;

                            tmrCardRead.running = false;
                            tmrCardRead.running = true;
                        }
                        font.pixelSize: 24
                        placeholderText: qsTr("Kart No")
                    }

                    Label{
                        id: lblCardError
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignTop
                        topPadding:5
                        visible: false
                        color: "red"
                        background: Rectangle{
                            anchors.fill: parent
                            anchors.bottomMargin: 10
                            color:"#22fa0202"
                            border.color: "red"
                            border.width: 1
                            radius: 5
                        }
                        horizontalAlignment: Text.AlignHCenter
                        text:'Tanımsız Kart'
                        font.bold: true
                        font.pixelSize: 18
                    }
                }
            }

            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.alignment: Qt.AlignBottom
                color: "transparent"

                RowLayout{
                    anchors.fill: parent

                    Button{
                        id: btnCardCancel
                        onClicked: function(){
                            popupCardRead.close();
                        }
                        text: "VAZGEÇ"
                        Layout.preferredWidth: parent.width * 0.5
                        Layout.fillHeight: true
                        font.pixelSize: 24
                        font.bold: true
                        padding: 5
                        leftPadding: 50
                        palette.buttonText: "#333"
                        background: Rectangle {
                            border.width: btnCardCancel.activeFocus ? 2 : 1
                            border.color: "#333"
                            radius: 4
                            gradient: Gradient {
                                GradientStop { position: 0 ; color: btnCardCancel.pressed ? "#AAA" : "#dedede" }
                                GradientStop { position: 1 ; color: btnCardCancel.pressed ? "#dedede" : "#AAA" }
                            }
                        }

                        Image {
                            anchors.top: btnCardCancel.top
                            anchors.left: btnCardCancel.left
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            sourceSize.width: 50
                            sourceSize.height: 30
                            fillMode: Image.Stretch
                            source: "../assets/back.png"
                        }
                    }

                    Button{
                        id: btnCardApply
                        text: "GİRİŞ"
                        onClicked: function(){
                            backend.requestEmployeeCard(txtCardNo.text);
                        }
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.pixelSize: 24
                        font.bold: true
                        padding: 5
                        leftPadding: 50
                        palette.buttonText: "#333"
                        background: Rectangle {
                            border.width: btnCardApply.activeFocus ? 2 : 1
                            border.color: "#326195"
                            radius: 4
                            gradient: Gradient {
                                GradientStop { position: 0 ; color: btnCardApply.pressed ? "#326195" : "#dedede" }
                                GradientStop { position: 1 ; color: btnCardApply.pressed ? "#dedede" : "#326195" }
                            }
                        }

                        Image {
                            anchors.top: btnCardApply.top
                            anchors.left: btnCardApply.left
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            sourceSize.width: 50
                            sourceSize.height: 30
                            fillMode: Image.Stretch
                            source: "../assets/login.png"
                        }
                    }
                }
            }
        }
    }

    // FORM COMPONENTS
    Component{
        id: cmpEmployeeList
        EmployeeList{
            employeeList: []
        }
    }

    Component{
        id: cmpShiftList
        ShiftList{
            shiftList: []
        }
    }

    Component{
        id: cmpProductList
        ProductList{
            productList: []
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
                Layout.leftMargin: 50
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
                                Layout.preferredWidth: parent.width * 0.4
                                Layout.fillHeight: true
                                color: "transparent"

                                ColumnLayout{
                                    anchors.fill: parent

                                    Button {
                                        id: btnProductCode
                                        onClicked: showProductList()
                                        Layout.fillWidth: true
                                        padding: 5
                                        text: ""
                                        background: Rectangle{
                                            border.width: btnProductCode.activeFocus ? 2 : 1
                                            border.color: "#9f9f9f"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnProductCode.pressed ? "#AAA" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnProductCode.pressed ? "#dedede" : "#AAA" }
                                            }
                                        }
                                        contentItem: Label {
                                            id: txtProductCode
                                            color:"#326195"
                                            text:"Ürün : "
                                            anchors.fill: parent
                                            minimumPointSize: 5
                                            font.pointSize: 16
                                            font.bold: true
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            // wrapMode: Label.Wrap
                                            // style: Text.Outline
                                            // styleColor:'#555'
                                        }
                                    }

                                    Button {
                                        id: btnOperatorName
                                        Layout.fillWidth: true
                                        onClicked: function(){
                                            popupCardRead.open();
                                        }//showEmployeeList()
                                        padding: 5
                                        text: ""
                                        background: Rectangle{
                                            border.width: btnOperatorName.activeFocus ? 2 : 1
                                            border.color: "#9f9f9f"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnOperatorName.pressed ? "#AAA" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnOperatorName.pressed ? "#dedede" : "#AAA" }
                                            }
                                        }
                                        contentItem: Label {
                                            id: txtOperatorName
                                            color:"#333"
                                            text:"Operatör: "
                                            anchors.fill: parent
                                            minimumPointSize: 5
                                            font.pointSize: 16
                                            font.bold: false
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            // wrapMode: Label.Wrap
                                            // style: Text.Outline
                                            // styleColor:'#555'
                                        }
                                    }

                                    Button {
                                        id: btnShiftCode
                                        onClicked: showShiftist()
                                        Layout.fillWidth: true
                                        padding: 5
                                        text: ""
                                        background: Rectangle{
                                            border.width: btnShiftCode.activeFocus ? 2 : 1
                                            border.color: "#9f9f9f"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnShiftCode.pressed ? "#AAA" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnShiftCode.pressed ? "#dedede" : "#AAA" }
                                            }
                                        }
                                        contentItem: Label {
                                            id: txtShiftCode
                                            color:"#333"
                                            text:"Vardiya: "
                                            anchors.fill: parent
                                            minimumPointSize: 5
                                            font.pointSize: 16
                                            font.bold: false
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            // wrapMode: Label.Wrap
                                            // style: Text.Outline
                                            // styleColor:'#555'
                                        }
                                    }
                                }
                            }

                            // BUTTONS
                            Rectangle{
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"

                                RowLayout{
                                    anchors.fill: parent

                                    Rectangle{
                                        Layout.preferredWidth: parent.width * 0.7
                                        Layout.fillHeight: true
                                        color: "blue"

                                    }

                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        Button{
                                            text: "Ayarlar"
                                            anchors.fill: parent
                                            onClicked: openSettings()
                                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                            id:btnSettings
                                            // font.pixelSize: 18
                                            // font.bold: true
                                            padding: 10
                                            contentItem:Label{
                                                anchors.fill: parent
                                                anchors.topMargin: 40
                                                minimumPointSize: 5
                                                font.pointSize: 16
                                                font.bold: false
                                                fontSizeMode: Text.Fit
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                text: "AYARLAR"
                                            }
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
                                                anchors.topMargin: btnSettings.height * 0.5 - 30
                                                anchors.leftMargin: btnSettings.width * 0.5 - 15
                                                sourceSize.width: 50
                                                sourceSize.height: 30
                                                fillMode: Image.Stretch
                                                source: "../assets/settings.png"
                                            }
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

                        // PRODUCT SECTIONS GRID PANEL
                        GridLayout {
                            id: gridProduct
                            anchors.fill: parent
                            anchors.bottomMargin: 5
                            columnSpacing: 5
                            rowSpacing: 2

                            Repeater{
                                id: rptGridProduct
                                
                                Rectangle{
                                    color: modelData.isShallow ? "transparent" : "#9dd2fa"
                                    border.width: modelData.isShallow ? 0 : 1
                                    border.color: "#326195"
                                    radius: 5
                                    Layout.column: modelData.posX
                                    Layout.row: modelData.posY
                                    Layout.rowSpan: modelData.sectionHeight
                                    Layout.columnSpan: modelData.sectionWidth
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: parent.height / gridProduct.rows * modelData.sectionHeight
                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        // anchors.fill: butterfly
                                        horizontalOffset: 3
                                        verticalOffset: 3
                                        radius: 8.0
                                        samples: 17
                                        color: "#80000000"
                                        // source: butterfly
                                    }
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#9dd2fa" }
                                        GradientStop { position: 1.0; color: "#326195" }
                                    }

                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: function(){
                                            
                                        }
                                    }

                                    Label{
                                        anchors.fill: parent
                                        text: modelData.sectionName ?? ''
                                        color: "#efefef"
                                        minimumPointSize: 5
                                        font.pointSize: 12
                                        font.bold: true
                                        fontSizeMode: Text.Fit
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        // wrapMode: Label.Wrap
                                        style: Text.Outline
                                        styleColor:'#333333'
                                    }
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