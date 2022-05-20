import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0

Item{
    id: settingsFormContainer

    property variant productList: []
    property variant employeeList: []
    property variant shiftList: []
    property var settingsModel: new Object({ id:0 })

    // ON LOAD EVENT
    Component.onCompleted: function(){
        bindProductList();
        // delay(100);
        // if (tabContent.currentItem != null)
        //     tabContent.replace(tabContent.currentItem, productTab);
    }

    function openTestView(){
        backend.requestShowTest();
    }

    function openProductForm(productId){
        var popup = cmpProductForm.createObject(settingsFormContainer, {
            recordId: productId
        });
        popup.open();
    }

    function bindProductList(){
        backend.requestProductList();
    }

    function filterProduct(){
        const filterRe = new RegExp(txtSearchProduct.text, 'i');
        const filteredList = productList.filter(d => 
            d.productNo.match(filterRe) || d.productName.match(filterRe)
        );
        rptProducts.model = filteredList;
    }

    function openEmployeeForm(employeeId){
        var popup = cmpEmployeeForm.createObject(settingsFormContainer, {
            recordId: employeeId
        });
        popup.open();
    }

    function bindEmployeeList(){
        backend.requestEmployeeList();
    }

    function filterEmployee(){
        const filterRe = new RegExp(txtSearchEmployee.text, 'i');
        const filteredList = employeeList.filter(d => 
            d.employeeCode.match(filterRe) || d.employeeName.match(filterRe)
        );
        rptEmplyoees.model = filteredList;
    }

    function openShiftForm(shiftId){
        var popup = cmpShiftForm.createObject(settingsFormContainer, {
            recordId: shiftId
        });
        popup.open();
    }

    function bindShiftList(){
        backend.requestShiftList();
    }

    function filterShift(){
        const filterRe = new RegExp(txtSearchShift.text, 'i');
        const filteredList = shiftList.filter(d => 
            d.shiftCode.match(filterRe)
        );
        rptShifts.model = filteredList;
    }

    function bindSettings(){
        backend.requestSettings();
    }

    function saveSettings(){
        if (!settingsModel)
            settingsModel = { id:0 };

        try {
            settingsModel.cameraIp = txtStgCameraIp.text;
            settingsModel.cameraPort = parseInt(txtStgCameraPort.text);
            settingsModel.robotIp = txtStgRobotIp.text;
            settingsModel.robotPort = parseInt(txtStgRobotPort.text);
            settingsModel.isFullPrm = txtStgIsFullPrm.text;
            settingsModel.rbFromSafetyHome = txtStgRbFromSafetyHome.text;
            settingsModel.rbToMasterJob = txtStgRbToMasterJob.text;
            settingsModel.rbToSafetyHome = txtStgRbToSafetyHome.text;
            settingsModel.valfPrm = txtStgValfPrm.text;

            backend.saveSettings(JSON.stringify(settingsModel));
        } catch (error) {
            console.log(error);
        }
    }

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onGetProductList(data){
            var products = JSON.parse(data);
            if (products){
                rptProducts.model = products;
                productList = products;
            }
            filterProduct();
        }

        function onProductListNeedsRefresh(){
            bindProductList();
        }

        function onGetEmployeeList(data){
            var employees = JSON.parse(data);
            if (employees){
                rptEmplyoees.model = employees;
                employeeList = employees;
            }
            filterEmployee();
        }

        function onEmployeeListNeedsRefresh(){
            bindEmployeeList();
        }

        function onGetShiftList(data){
            var shifts = JSON.parse(data);
            if (shifts){
                rptShifts.model = shifts;
                shiftList = shifts;
            }
            filterShift();
        }

        function onShiftListNeedsRefresh(){
            bindShiftList();
        }

        function onGetSettings(data){
            let stObj = null;
            try {
                stObj = JSON.parse(data);
            } catch (error) {
                
            }

            if (!stObj)
                stObj = { id:0 };
            
            settingsModel = stObj;

            try {
                txtStgCameraIp.text = settingsModel.cameraIp;
                txtStgCameraPort.text = (settingsModel.cameraPort ?? 0).toString();
                txtStgRobotIp.text = settingsModel.robotIp;
                txtStgRobotPort.text = (settingsModel.robotPort ?? 0).toString();
                txtStgIsFullPrm.text = settingsModel.isFullPrm;
                txtStgRbFromSafetyHome = settingsModel.rbFromSafetyHome;
                txtStgRbToMasterJob.text = settingsModel.rbToMasterJob;
                txtStgRbToSafetyHome.text = settingsModel.rbToSafetyHome;
                txtStgValfPrm.text = settingsModel.valfPrm;
            } catch (error) {
                
            }
        }

        function onSaveSettingsFinished(data){
            const postResult = JSON.parse(data);
            if (postResult.Result)
                lblSaveSettingsResult.text = 'OK';
            else
                lblSaveSettingsResult.text = postResult.ErrorMessage;
        }
    }

    // FORM COMPONENTS
    Component{
        id: cmpProductForm
        ProductForm{
            recordId: 0
        }
    }

    Component{
        id: cmpEmployeeForm
        EmployeeForm{
            recordId: 0
        }
    }

    Component{
        id: cmpShiftForm
        ShiftForm{
            recordId: 0
        }
    }

    // VIEW LAYOUT
    Rectangle{
        anchors.fill: parent
        color: "#c8cacc"

        ColumnLayout{
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            spacing: 0

            // HEADER BAR & BACK BUTTON
            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: 65
                Layout.alignment: Qt.AlignTop
                color: "transparent"

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    color:"#333"
                    padding: 2
                    font.pixelSize: 36
                    font.bold: true
                    text: "Uygulama Ayarları"
                }

                Button{
                    anchors.rightMargin:10
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    text: "Geri Dön"
                    onClicked: openTestView()
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
                        source: "../assets/back.png"
                    }
                }
            }

            // TAB PANEL
            TabBar{
                id: tabBar
                Layout.fillWidth: true

                TabButton{
                    text: "Ürün"
                    icon.source: "../assets/climate.png"
                    font.pixelSize: 18
                    onClicked: function(){
                        if (tabContent.currentItem != productTab){
                            bindProductList();
                            tabContent.replace(tabContent.currentItem, productTab);
                        }
                    }
                }

                TabButton{
                    text: "Personel"
                    icon.source: "../assets/employee.png"
                    font.pixelSize: 18
                    onClicked: function(){
                        if (tabContent.currentItem != employeeTab){
                            bindEmployeeList();
                            tabContent.replace(tabContent.currentItem, employeeTab);
                        }
                    }
                }

                TabButton{
                    text: "Vardiya"
                    icon.source: "../assets/shift.png"
                    font.pixelSize: 18
                    onClicked: function(){
                        if (tabContent.currentItem != shiftTab){
                            bindShiftList();
                            tabContent.replace(tabContent.currentItem, shiftTab);
                        }
                    }
                }

                TabButton{
                    text: "Bağlantı Ayarları"
                    icon.source: "../assets/settings.png"
                    font.pixelSize: 18
                    onClicked: function(){
                        if (tabContent.currentItem != settingsTab){
                            bindSettings();
                            lblSaveSettingsResult.text = '';
                            tabContent.replace(tabContent.currentItem, settingsTab);
                        }
                    }
                }

                TabButton{
                    text: "Rapor"
                    icon.source: "../assets/report.png"
                    font.pixelSize: 18
                    onClicked: function(){
                        if (tabContent.currentItem != reportTab)
                            tabContent.replace(tabContent.currentItem, reportTab);
                    }
                }
            }

            StackView{
                id: tabContent
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                initialItem: productTab

                Item {
                    id: productTab
                    Rectangle{ 
                        anchors.fill: parent
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
                                        id: txtSearchProduct
                                        Layout.alignment: Qt.AlignLeft
                                        Layout.preferredWidth: parent.width * 0.6
                                        
                                        font.pixelSize: 24
                                        placeholderText: qsTr("Arama")
                                        onTextChanged: function(){
                                            filterProduct();
                                        }
                                    }

                                    Button{
                                        text: "Yeni Ürün"
                                        onClicked: openProductForm(0)
                                        Layout.alignment: Qt.AlignRight
                                        id:btnNewProduct
                                        font.pixelSize: 18
                                        font.bold: true
                                        padding: 10
                                        leftPadding: 50
                                        palette.buttonText: "#333"
                                        background: Rectangle {
                                            border.width: btnNewProduct.activeFocus ? 2 : 1
                                            border.color: "#326195"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnNewProduct.pressed ? "#326195" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnNewProduct.pressed ? "#dedede" : "#326195" }
                                            }
                                        }

                                        Image {
                                            anchors.top: btnNewProduct.top
                                            anchors.left: btnNewProduct.left
                                            anchors.topMargin: 5
                                            anchors.leftMargin: 10
                                            sourceSize.width: 50
                                            sourceSize.height: 30
                                            fillMode: Image.Stretch
                                            source: "../assets/add.png"
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
                                        Layout.preferredWidth: parent.width * 0.3
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
                                            text: "Ürün Kodu"
                                        }
                                    }

                                    Rectangle{
                                        Layout.preferredWidth: parent.width * 0.7 - 100
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
                                            text: "Ürün Adı"
                                        }
                                    }

                                    Rectangle{
                                        Layout.preferredWidth: 100
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
                                            text: ""
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
                                            id: rptProducts
                                            
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 50
                                                Layout.alignment: Qt.AlignTop
                                                color: "#efefef"
                                                
                                                RowLayout{
                                                    anchors.fill: parent
                                                    spacing: 0

                                                    LinearGradient {
                                                        Layout.preferredWidth: parent.width * 0.3
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
                                                            text: modelData.productNo
                                                        }
                                                    }

                                                    Rectangle{
                                                        Layout.preferredWidth: parent.width * 0.7 - 100
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
                                                            text: modelData.productName
                                                        }
                                                    }

                                                    Rectangle{
                                                        Layout.preferredWidth: 100
                                                        Layout.fillHeight: true
                                                        color: "transparent"

                                                        Button{
                                                            onClicked: function(){
                                                                openProductForm(modelData.id);
                                                            }
                                                            width: 49
                                                            height: parent.height - 10
                                                            anchors.top: parent.top
                                                            anchors.topMargin: 5
                                                            padding: 5
                                                            background: Rectangle {
                                                                border.width: parent.activeFocus ? 2 : 1
                                                                border.color: "#326195"
                                                                radius: 4
                                                                gradient: Gradient {
                                                                    GradientStop { position: 0 ; color: parent.pressed ? "#326195" : "#dedede" }
                                                                    GradientStop { position: 1 ; color: parent.pressed ? "#dedede" : "#326195" }
                                                                }
                                                            }
                                                            Image {
                                                                anchors.top: parent.top
                                                                anchors.left: parent.left
                                                                anchors.topMargin: 5
                                                                anchors.leftMargin: 10
                                                                sourceSize.width: 50
                                                                sourceSize.height: 30
                                                                fillMode: Image.Stretch
                                                                source: "../assets/edit.png"
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
                Item {
                    id: employeeTab
                    visible: tabContent.currentItem == employeeTab
                    Rectangle {
                        anchors.fill: parent
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
                                        id: txtSearchEmployee
                                        Layout.alignment: Qt.AlignLeft
                                        Layout.preferredWidth: parent.width * 0.6
                                        
                                        font.pixelSize: 24
                                        placeholderText: qsTr("Arama")
                                        onTextChanged: function(){
                                            filterEmployee();
                                        }
                                    }

                                    Button{
                                        text: "Yeni Personel"
                                        onClicked: openEmployeeForm(0)
                                        Layout.alignment: Qt.AlignRight
                                        id:btnNewEmployee
                                        font.pixelSize: 18
                                        font.bold: true
                                        padding: 10
                                        leftPadding: 50
                                        palette.buttonText: "#333"
                                        background: Rectangle {
                                            border.width: parent.activeFocus ? 2 : 1
                                            border.color: "#326195"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnNewEmployee.pressed ? "#326195" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnNewEmployee.pressed ? "#dedede" : "#326195" }
                                            }
                                        }

                                        Image {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.topMargin: 5
                                            anchors.leftMargin: 10
                                            sourceSize.width: 50
                                            sourceSize.height: 30
                                            fillMode: Image.Stretch
                                            source: "../assets/add.png"
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
                                            text: "Personel Kodu"
                                        }
                                    }

                                    Rectangle{
                                        Layout.preferredWidth: parent.width * 0.6 - 100
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
                                            text: "Personel Adı"
                                        }
                                    }

                                    Rectangle{
                                        Layout.preferredWidth: 100
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
                                            text: ""
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
                                            id: rptEmplyoees

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 50
                                                Layout.alignment: Qt.AlignTop
                                                color: "#efefef"
                                                
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
                                                            text: modelData.employeeCode
                                                        }
                                                    }

                                                    Rectangle{
                                                        Layout.preferredWidth: parent.width * 0.6 - 100
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
                                                            text: modelData.employeeName
                                                        }
                                                    }

                                                    Rectangle{
                                                        Layout.preferredWidth: 100
                                                        Layout.fillHeight: true
                                                        color: "transparent"

                                                        Button{
                                                            onClicked: function(){
                                                                openEmployeeForm(modelData.id);
                                                            }
                                                            width: 49
                                                            height: parent.height - 10
                                                            anchors.top: parent.top
                                                            anchors.topMargin: 5
                                                            padding: 5
                                                            background: Rectangle {
                                                                border.width: parent.activeFocus ? 2 : 1
                                                                border.color: "#326195"
                                                                radius: 4
                                                                gradient: Gradient {
                                                                    GradientStop { position: 0 ; color: parent.pressed ? "#326195" : "#dedede" }
                                                                    GradientStop { position: 1 ; color: parent.pressed ? "#dedede" : "#326195" }
                                                                }
                                                            }
                                                            Image {
                                                                anchors.top: parent.top
                                                                anchors.left: parent.left
                                                                anchors.topMargin: 5
                                                                anchors.leftMargin: 10
                                                                sourceSize.width: 50
                                                                sourceSize.height: 30
                                                                fillMode: Image.Stretch
                                                                source: "../assets/edit.png"
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
                Item {
                    id: shiftTab
                    visible: tabContent.currentItem == shiftTab
                    
                    Rectangle {
                        anchors.fill: parent
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

                                    Button{
                                        text: "Yeni Vardiya"
                                        onClicked: openShiftForm(0)
                                        Layout.alignment: Qt.AlignRight
                                        id:btnNewShift
                                        font.pixelSize: 18
                                        font.bold: true
                                        padding: 10
                                        leftPadding: 50
                                        palette.buttonText: "#333"
                                        background: Rectangle {
                                            border.width: parent.activeFocus ? 2 : 1
                                            border.color: "#326195"
                                            radius: 4
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnNewShift.pressed ? "#326195" : "#dedede" }
                                                GradientStop { position: 1 ; color: btnNewShift.pressed ? "#dedede" : "#326195" }
                                            }
                                        }

                                        Image {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.topMargin: 5
                                            anchors.leftMargin: 10
                                            sourceSize.width: 50
                                            sourceSize.height: 30
                                            fillMode: Image.Stretch
                                            source: "../assets/add.png"
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
                                        Layout.preferredWidth: parent.width * 0.3 - 100
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

                                    Rectangle{
                                        Layout.preferredWidth: 100
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
                                            text: ""
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
                                                        Layout.preferredWidth: parent.width * 0.3 - 100
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

                                                    Rectangle{
                                                        Layout.preferredWidth: 100
                                                        Layout.fillHeight: true
                                                        color: "transparent"

                                                        Button{
                                                            onClicked: function(){
                                                                openShiftForm(modelData.id);
                                                            }
                                                            width: 49
                                                            height: parent.height - 10
                                                            anchors.top: parent.top
                                                            anchors.topMargin: 5
                                                            padding: 5
                                                            background: Rectangle {
                                                                border.width: parent.activeFocus ? 2 : 1
                                                                border.color: "#326195"
                                                                radius: 4
                                                                gradient: Gradient {
                                                                    GradientStop { position: 0 ; color: parent.pressed ? "#326195" : "#dedede" }
                                                                    GradientStop { position: 1 ; color: parent.pressed ? "#dedede" : "#326195" }
                                                                }
                                                            }
                                                            Image {
                                                                anchors.top: parent.top
                                                                anchors.left: parent.left
                                                                anchors.topMargin: 5
                                                                anchors.leftMargin: 10
                                                                sourceSize.width: 50
                                                                sourceSize.height: 30
                                                                fillMode: Image.Stretch
                                                                source: "../assets/edit.png"
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
                Item{
                    id: settingsTab
                    visible: tabContent.currentItem == settingsTab
                    Rectangle{ 
                        anchors.fill: parent
                        color: "transparent"

                        ColumnLayout{
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: parent.width / 2
                            anchors.leftMargin: 5
                            anchors.rightMargin: 5
                            anchors.topMargin: 10

                             // ROBOT FIELDS
                            Rectangle{
                                Layout.preferredHeight: 50
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                Layout.margins: 2
                                color: "transparent"

                                RowLayout{
                                    anchors.fill: parent

                                    // ROBOT IP FIELD
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Robot Ip'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgRobotIp
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }

                                    // ROBOT PORT FIELD
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Robot Port'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgRobotPort
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // CAMERA FIELDS
                            Rectangle{
                                Layout.preferredHeight: 50
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                Layout.margins: 2
                                color: "transparent"

                                RowLayout{
                                    anchors.fill: parent

                                    // CAMERA IP FIELD
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Kamera Ip'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgCameraIp
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }

                                    // CAMERA PORT FIELD
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Kamera Port'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgCameraPort
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ROBOT HOME POS PRM
                            Rectangle{
                                Layout.preferredHeight: 50
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                Layout.margins: 2
                                color: "transparent"

                                RowLayout{
                                    anchors.fill: parent

                                    // RB TO SAFETY HOME
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Home Position Git'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgRbToSafetyHome
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }

                                    // RB FROM SAFETY HOME
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Safety Home Varış Sinyali'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgRbFromSafetyHome
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // IS FULL & VALF PRMS
                            Rectangle{
                                Layout.preferredHeight: 50
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                Layout.margins: 2
                                color: "transparent"

                                RowLayout{
                                    anchors.fill: parent

                                    // IS FULL PRM
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Ürün Var Bilgisi'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgIsFullPrm
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }

                                    // VALF PRM
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignTop
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent

                                            Label{
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 15
                                                Layout.alignment: Qt.AlignTop
                                                horizontalAlignment: Text.AlignLeft
                                                text:'Valf Bilgisi'
                                                font.pixelSize: 12
                                            }

                                            TextField {
                                                id: txtStgValfPrm
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                                font.pixelSize: 9
                                                padding: 10
                                                background: Rectangle {
                                                    radius: 5
                                                    border.color: parent.focus ? "#326195" : "#888"
                                                    border.width: 1
                                                    color: parent.focus ? "#efefef" : "#ffffff"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ROBOT MASTER JOB PRM
                            Rectangle{
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                Layout.alignment: Qt.AlignTop
                                Layout.margins: 2
                                color: "transparent"

                                ColumnLayout{
                                    anchors.fill: parent

                                    Label{
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 15
                                        Layout.alignment: Qt.AlignTop
                                        horizontalAlignment: Text.AlignLeft
                                        text:'Master Job Bilgisi'
                                        font.pixelSize: 12
                                    }

                                    TextField {
                                        id: txtStgRbToMasterJob
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                        font.pixelSize: 9
                                        padding: 10
                                        background: Rectangle {
                                            radius: 5
                                            border.color: parent.focus ? "#326195" : "#888"
                                            border.width: 1
                                            color: parent.focus ? "#efefef" : "#ffffff"
                                        }
                                    }
                                }
                            }
                            
                            // ACTION BUTTONS
                            Rectangle{
                                Layout.preferredHeight: 50
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                Layout.margins: 2
                                color: "transparent"

                                RowLayout{
                                    anchors.fill: parent
                                    spacing: 10

                                    // SETTINGS SAVE BUTTON
                                    Button{
                                        onClicked: saveSettings()
                                        Layout.preferredWidth: 100
                                        Layout.fillHeight: true
                                        padding: 5
                                        background: Rectangle {
                                            color: "#24d151"
                                            border.width: 1
                                            border.color: "#333"
                                            radius: 4
                                        }
                                        Image {
                                            anchors.centerIn: parent
                                            sourceSize.width: 50
                                            sourceSize.height: 30
                                            fillMode: Image.Stretch
                                            source: "../assets/save.png"
                                        }
                                    }

                                    Label{
                                        id: lblSaveSettingsResult
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        verticalAlignment: Qt.AlignVCenter
                                        horizontalAlignment: Qt.AlignLeft
                                        color: "#333"
                                        font.bold: true
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
                Item{
                    id: reportTab
                    Rectangle{ anchors.fill: parent}
                }
            }
        }
    }
}