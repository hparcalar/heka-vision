import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0
import QtQuick.Extras 1.4
import QtQuick.Dialogs 1.1
import "controls"

Item{
    id: testViewFormContainer

    FontLoader { id: customFont; source:'../assets/ttl.ttf' }

    property string sectionList
    property int loginState: 0
    property int runningStepId: -1
    property bool robotStartPosArrived: false
    property bool testRunning: false
    property bool isFullByProduct: false
    property bool selectionIsValid: false
    property string selectionValidMsg : ''
    property bool robotCommOk: false
    property bool camCommOk: false
    property int lastTestStatus: 0
    property string showingCaptureImage: ''
    property bool robotHoldStatus: false

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
        requestLiveStats();

        popupCardRead.open();

        backend.initDevices();
        backend.startCommCheck();
        backend.startProductSensorCheck();

        btnReset.enabled = false;
        checkSelectionsAreValid();
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
                        images: partObj.images && partObj.images.length > 0 ? partObj.images : [],
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
                    controlStatus: st.liveStatus,
                    controlResult: st.liveResult,
                    isRunning: st.id == runningStepId,
                    faultCount: st.faultCount ?? 0,
                });
            });
        }
    }

    function openSettings(){
        popupAuth.open();
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
                    isRunning: false,
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
                        isRunning: activeProduct.steps.some(m => m.id == runningStepId && m.sectionId == d.id)
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

    function showCaptureImage(camImage){
        backend.requestCaptureImage(camImage);
    }

    function refreshScreen(){
        backend.requestShowTest();
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

    function testReset(){
        var errMsg = '';
        var isValid = true;
        if (activeProduct.id <= 0){
            errMsg = 'Başlamak için bir ürün seçmelisiniz.';
            isValid = false;
        }
        else if (activeEmployee.id <= 0){
            errMsg = 'Başlamak için personel kartınızı okutmalısınız.';
            isValid = false;
        }
        else if (activeShift.id <= 0){
            errMsg = 'Başlamak için vardiya seçmelisiniz.';
            isValid = false;
        }

        if (!isValid){
            errorDialog.text = errMsg;
            errorDialog.visible = true;
            return;
        }

        testRunning = true;
        robotStartPosArrived = false;

        // clear current active results
        try {
            if (activeProduct.steps != null && activeProduct.steps.length > 0)
                runningStepId = activeProduct.steps[0].id;
            else
                runningStepId = -1;

            activeProduct.steps.forEach(d => {
                d.liveStatus = false;
                d.liveResult = false;
            });

            activeProduct.sections.forEach(d => {
                d.images = [];
            });

            drawParts();
            bindTestSteps();
            bindGridSchema();
        } catch (error) {
            
        }

        lastTestStatus = 0;
        btnReset.enabled = false;
        backend.resetTest(activeProduct.id);
    }

    function setRobotHold(){
        testRunning = false;

        backend.setRobotHold();
        btnReset.enabled = true;
        btnMasterJobCall.enabled = false;
        btnServoOn.enabled = false;
        btnStart.enabled = false;

        checkSelectionsAreValid();
    }

    function requestLiveStats(){
        let prId = null;
        let shId = null;

        if (activeProduct && activeProduct.id > 0)
            prId = activeProduct.id;
        else
            prId = 0;
        
        if (activeShift && activeShift.id > 0)
            shId = activeShift.id;
        else
            shId = 0;

        if (shId > 0){
            backend.requestLiveStatus(prId, shId);
        }
    }

    function openHatch(){
        backend.openHatch();
    }

    function closeHatch(){
        backend.closeHatch();
    }

    function checkSelectionsAreValid(){
        let tmpIsValid = true;
        if (activeProduct == null || activeProduct.id <= 0){
            tmpIsValid = false;
            selectionValidMsg = 'Ürün seçiniz';
        }
        else if (activeEmployee == null || activeEmployee.id <= 0){
            tmpIsValid = false;
            selectionValidMsg = 'Kartınızı Okutun';
        }
        else if (activeShift == null || activeShift.id <= 0){
            tmpIsValid = false;
            selectionValidMsg = 'Vardiya Seçin';
        }

        selectionIsValid = tmpIsValid;
        if (selectionIsValid == false){
            btnStart.enabled = false;
            backend.stopListenerForStartButton();
        }
        else{
            backend.startListenStartButton();
        }
    }

    function saveTestResult(testResult){
        if (activeProduct != null && activeProduct.id > 0){
            const foundStep = activeProduct.steps.find(d => d.id == runningStepId);

            backend.saveTestResult(JSON.stringify({
                productId: activeProduct.id,
                sectionId: foundStep ? foundStep.sectionId : null,
                stepId: foundStep ? foundStep.id : null,
                shiftId: activeShift && activeShift.id > 0 ? activeShift.id : null,
                employeeId: activeEmployee && activeEmployee.id > 0 ? activeEmployee.id : null,
                isOk: testResult,
                steps: activeProduct.steps, // for saving step detail results
                sections: activeProduct.sections, // for saving section based image results
            }));
        }
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
            requestLiveStats();
            checkSelectionsAreValid();
        }

        function onProductSelected(data){
            activeProduct = JSON.parse(data);
            if (activeProduct.sections)
                activeProduct.sections = activeProduct.sections.sort((a,b) => a.orderNo - b.orderNo);

            bindProduct();
            requestLiveStats();
            checkSelectionsAreValid();
        }

        function onEmployeeCardRead(data){
            activeEmployee = JSON.parse(data);
            if (activeEmployee){
                popupCardRead.close();
                bindEmployee();
                checkSelectionsAreValid();
            }
            else{
                silentDateSet = false;
                silentCardNo = "";
                lblCardError.visible = true;
                txtCardNo.text = "";
            }
        }

        function onGetDeviceStatus(data){
            var resObj = JSON.parse(data);
            if (resObj){
                if (resObj.Robot == true)
                    txtRobotStatus.color = "#32a852";
                else
                    txtRobotStatus.color = "red";

                if (resObj.Camera == true)
                    txtCameraStatus.color = "#32a852";
                else
                    txtCameraStatus.color = "red";

                robotCommOk = resObj.Robot;
                camCommOk = resObj.Camera;

                txtRobotStatus.text = resObj.Robot == true ? ': OK' : ': NOK';
                txtCameraStatus.text = resObj.Camera == true ? ': OK' : ': NOK';
            }
        }

        function onGetResetOk(){
            btnReset.enabled = false;
            btnMasterJobCall.enabled = true;
            btnServoOn.enabled = false;
            btnStart.enabled = false;
        }

        function onGetMasterJobOk(){
            btnReset.enabled = false;
            btnMasterJobCall.enabled = false;
            btnServoOn.enabled = true;
            btnStart.enabled = false;
        }

        function onGetServoOnOk(){
            btnReset.enabled = false;
            btnMasterJobCall.enabled = false;
            btnServoOn.enabled = false;
            btnStart.enabled = true;
        }

        function onGetStartOk(){
            btnReset.enabled = false;
            btnMasterJobCall.enabled = false;
            btnServoOn.enabled = false;
            btnStart.enabled = false;
        }

        function onTestStepError(data){
            btnReset.enabled = true;
            btnMasterJobCall.enabled = false;
            btnServoOn.enabled = false;
            btnStart.enabled = false;

            testRunning = false;

            if (errorDialog.visible == false){
                errorDialog.text = data;
                errorDialog.visible = true;
            }

            checkSelectionsAreValid();
        }

        function onGetStepResult(data){
            robotStartPosArrived = false;
            var stepRes = JSON.parse(data);
            if (stepRes){
                const stepId = parseInt(stepRes.Message);
                const foundStep = activeProduct.steps.find(d => d.id == stepId);
                if (foundStep){
                    foundStep.liveStatus = true;
                    foundStep.liveResult = stepRes.Result;
                    foundStep.detailResult = stepRes.Details;

                    // save fault step result before reset
                    // if (stepRes.Result == false){
                    //     saveTestResult(false);
                    //     lastTestStatus = 2;
                    //     // testRunning = false;
                    // }

                    const foundStepIndex = activeProduct.steps.indexOf(foundStep);
                    const nextStep = activeProduct.steps.length > (foundStepIndex + 1) ?
                        activeProduct.steps[foundStepIndex + 1] : null;
                    if (nextStep){
                        runningStepId = nextStep.id;
                    }
                    else
                        runningStepId = -1;

                    bindTestSteps();
                    bindGridSchema();
                }
            }
        }

        function onGetAllStepsFinished(){
            const finalTestResult = !activeProduct.steps.some(d => d.liveResult == false);
            saveTestResult(finalTestResult);

            lastTestStatus = finalTestResult == true ? 1 : 2;

            btnReset.enabled = true;
            btnMasterJobCall.enabled = false;
            btnServoOn.enabled = false;
            btnStart.enabled = false;
            robotStartPosArrived = false;
            testRunning = false;
            backend.startListenStartButton();
        }

        function onTestResultSaved(data){
            requestLiveStats();
        }

        function onGetLiveStatus(data){
            const dataObj = JSON.parse(data);
            if (dataObj){
                txtTotalTestCount.text = ': ' + dataObj.Live.totalCount.toString();
                txtTotalFaultCount.text = ': ' + dataObj.Live.faultCount.toString();
                txtTotalOkCount.text = ': ' + (dataObj.Live.totalCount - dataObj.Live.faultCount).toString();
                const okCount = (dataObj.Live.totalCount - dataObj.Live.faultCount);
                let oeeValue = parseInt((okCount / (dataObj.Live.totalCount * 1.0)) * 100);
                if (!(oeeValue > 0))
                    oeeValue = 0;
                
                oeeSlider.value = oeeValue;

                if (dataObj.Steps){
                    dataObj.Steps.forEach(d => {
                        const foundStep = activeProduct.steps.find(m => m.id == d.id);
                        if (foundStep){
                            foundStep.faultCount = d.faultCount;
                        }
                    });

                    bindTestSteps();
                }
            }
        }

        function onGetStartPosArrived(){
            robotStartPosArrived = true;
        }

        function onGetProductSensor(isFull){
            isFullByProduct = isFull;

            if (testRunning == false)
            {
                if (selectionIsValid == false)
                    btnReset.enabled = false;
                else
                    btnReset.enabled = isFullByProduct;
            }
            else{
                if (isFullByProduct == false){
                    setRobotHold();
                }
                else
                    btnReset.enabled = false;
            }
        }

        function onGetNewImageResult(fullImagePath, recipeId){
            try {
                const properStep = activeProduct.steps.find(d => d.camRecipeId == recipeId);
                if (properStep && properStep.sectionId > 0){
                    const properSection = activeProduct.sections.find(d => d.id == properStep.sectionId);
                    if (properSection){
                        if (!properSection.images || properSection.images == null)
                            properSection.images = [];
                        properSection.images.push(fullImagePath);
                        drawParts();
                    }
                }
            } catch (error) {
                
            }
        }

        function onGetCaptureImage(captureImage){
            if (captureImage && captureImage.length > 0){
                showingCaptureImage = captureImage;
                popupCaptureImage.open();
            }
        }

        function onGetRobotHoldChanged(holdStatus){
            if (holdStatus != null){
                robotHoldStatus = holdStatus;
            }
        }

        function onGetStartButtonPressed(){
            testReset();
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
                                if (txtLoginPassword.text.indexOf('0006013789') > -1 || txtLoginPassword.text == '8910'){
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
                            if (txtLoginPassword.text.indexOf('0006013789') > -1 || txtLoginPassword.text == '8910'){
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

                            if (event.text && event.text != '\r\n' && event.text != '\r' && event.text != '\n')
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

    Popup {
        id: popupCaptureImage
        modal: true
        dim: true
        Overlay.modal: Rectangle {
            color: "#aacfdbe7"
        }

        anchors.centerIn: parent
        width: parent.width * 0.95
        height: parent.height * 0.95

        enter: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1 }
        }

        exit: Transition {
            NumberAnimation { properties: "opacity"; from: 1; to: 0 }
        }

        ColumnLayout{
            anchors.fill: parent

            Label{
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                horizontalAlignment: Text.AlignHCenter
                text:'Tespit Detayları'
                font.bold: true
                font.pixelSize: 24
            }

            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                Image {
                    id: imgDetails
                    anchors.centerIn: parent
                    sourceSize.height: parent.height
                    fillMode: Image.PreserveAspectFit
                    source: showingCaptureImage
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
                        id: btnCaptureDialogClose
                        onClicked: function(){
                            popupCaptureImage.close();
                        }
                        text: "KAPAT"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.pixelSize: 24
                        font.bold: true
                        padding: 5
                        leftPadding: 50
                        palette.buttonText: "#333"
                        background: Rectangle {
                            border.width: btnCaptureDialogClose.activeFocus ? 2 : 1
                            border.color: "#333"
                            radius: 4
                            gradient: Gradient {
                                GradientStop { position: 0 ; color: btnCaptureDialogClose.pressed ? "#AAA" : "#dedede" }
                                GradientStop { position: 1 ; color: btnCaptureDialogClose.pressed ? "#dedede" : "#AAA" }
                            }
                        }

                        Image {
                            anchors.top: btnCaptureDialogClose.top
                            anchors.left: btnCaptureDialogClose.left
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            sourceSize.width: 50
                            sourceSize.height: 30
                            fillMode: Image.Stretch
                            source: "../assets/back.png"
                        }
                    }
                }
            }
        }
    }

    MessageDialog {
        id: errorDialog
        title: "HATA"
        text: ""
        visible: false
        icon: StandardIcon.Warning
        onAccepted: {
            errorDialog.visible = false;
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
            property var images

            color:"transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                anchors.fill: parent
                spacing:0

                // PART NAME
                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height / 3 - 20
                    color: "#326195"

                    Text {
                        font.family: customFont.name
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color:"#FFFFFF"
                        padding: 3
                        // font.pixelSize: 18
                        minimumPointSize: 5
                        font.pointSize: 14
                        fontSizeMode: Text.Fit
                        font.bold: true
                        text: partName
                    }
                }

                // PART IMAGES
                Rectangle{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "black"

                    RowLayout{
                        anchors.fill: parent

                        Repeater{
                            model: images

                            Image {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                asynchronous: true
                                sourceSize.height: parent.height
                                fillMode: Image.Stretch
                                source: modelData

                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: function(){
                                        showCaptureImage(parent.source);
                                    }
                                }
                            }
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
            property bool controlResult: false
            property bool isRunning: false
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
                        GradientStop { position: 0.0; color: isRunning ? "#4cdb2c" : "#326195" }
                        GradientStop { position: 1.0; color: "#c8cacc" }
                    }

                    Text {
                        font.family: customFont.name
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color:"#fff"
                        padding: 2
                        leftPadding: 10
                        minimumPointSize: 5
                        font.pointSize: 14
                        fontSizeMode: Text.Fit
                        font.bold: true
                        text: controlSection
                    }
                }

                Rectangle{
                    Layout.preferredWidth: parent.width * 0.3
                    Layout.fillHeight: true
                    color: "transparent"

                    Image {
                        visible: controlStatus
                        anchors.centerIn: parent
                        sourceSize.width: 50
                        sourceSize.height: parent.height - 5
                        fillMode: Image.Stretch
                        source: controlResult ? "../assets/ok.png" : "../assets/error.png"
                    }
                }

                Rectangle{
                    Layout.preferredWidth: parent.width * 0.3
                    Layout.fillHeight: true
                    color: "transparent"

                    Text {
                        font.family: customFont.name
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color:"#333"
                        padding: 2
                        minimumPointSize: 5
                        font.pointSize: 14
                        fontSizeMode: Text.Fit
                        font.bold: false
                        text: faultCount.toString()
                    }
                }
            }
        }
    }

    Gradient {
        id: gradientProduct
        GradientStop { position: 0.0; color: "#9dd2fa" }
        GradientStop { position: 1.0; color: "#548ac4" }
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
                Layout.preferredWidth: parent.width * 0.27
                Layout.fillHeight: true
                Layout.leftMargin: 5
                Layout.bottomMargin: 5
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
                Layout.leftMargin: 5
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
                                Layout.preferredWidth: parent.width * 0.3
                                Layout.fillHeight: true
                                color: "transparent"

                                ColumnLayout{
                                    anchors.fill: parent

                                    Button {
                                        id: btnProductCode
                                        onClicked: refreshScreen()
                                        Layout.fillWidth: true
                                        padding: 2
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
                                            font.family: customFont.name
                                            font.pointSize: 14
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
                                        padding: 2
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
                                            font.family: customFont.name
                                            minimumPointSize: 5
                                            font.pointSize: 14
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
                                        padding: 2
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
                                            font.family: customFont.name
                                            minimumPointSize: 5
                                            font.pointSize: 14
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

                            // HATCH CONTROL BUTTONS
                            Rectangle{
                                visible: testRunning == false && robotCommOk == true
                                Layout.preferredWidth: parent.width * 0.12
                                Layout.fillHeight: true
                                color: "transparent"

                                ColumnLayout{
                                    anchors.fill: parent
                                    spacing: 2

                                    Button{
                                        text: ""
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: parent.height * 0.5
                                        onClicked: function(){
                                            openHatch();
                                        }
                                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                        id:btnOpenHatch
                                        padding: 10
                                        contentItem:Label{
                                            anchors.fill: parent
                                            minimumPointSize: 5
                                            anchors.leftMargin: 20
                                            font.pointSize: 14
                                            font.bold: true
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            text: ""
                                        }
                                        palette.buttonText: "#333"
                                        background: Rectangle {
                                            border.width: btnOpenHatch.activeFocus ? 2 : 1
                                            border.color: "#333"
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnOpenHatch.pressed ? "#dedede" : "#afafaf" }
                                                GradientStop { position: 1 ; color: btnOpenHatch.pressed ? "#afafaf" : "#dedede" }
                                            }
                                        }

                                        Image {
                                            anchors.centerIn: parent
                                            sourceSize.height: parent.height * 0.8
                                            fillMode: Image.PreserveAspectFit
                                            source: "../assets/arrow_up.png"
                                        }
                                    }

                                    Button{
                                        text: ""
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        id: btnCloseHatch
                                        onClicked: function(){
                                            closeHatch();
                                        }
                                        enabled: true
                                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                        padding: 10
                                        contentItem:Label{
                                            anchors.fill: parent
                                            minimumPointSize: 5
                                            font.pointSize: 14
                                            anchors.leftMargin: 20
                                            font.bold: true
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            text: ""
                                        }
                                        palette.buttonText: "#fff"
                                        background: Rectangle {
                                            border.width: btnCloseHatch.activeFocus ? 2 : 1
                                            border.color: "#333"
                                            gradient: Gradient {
                                                GradientStop { position: 0 ; color: btnCloseHatch.pressed ? "#dedede" : "#afafaf" }
                                                GradientStop { position: 1 ; color: btnCloseHatch.pressed ? "#afafaf" : "#dedede" }
                                            }
                                        }

                                        Image {
                                            anchors.centerIn: parent
                                            sourceSize.height: parent.height * 0.8
                                            fillMode: Image.PreserveAspectFit
                                            source: "../assets/arrow_down.png"
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

                                    // ROBOT PROCESS BUTTONS
                                    Rectangle{
                                        Layout.preferredWidth: parent.width * 0.7
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        RowLayout{
                                            visible: !(isFullByProduct == false && testRunning == false) || selectionIsValid == false
                                            anchors.fill: parent
                                            spacing:0

                                            Button{
                                                text: ""
                                                Layout.preferredWidth: parent.width * 0.25
                                                Layout.fillHeight: true
                                                id: btnReset
                                                onClicked: testReset()
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                padding: 10
                                                contentItem:Label{
                                                    anchors.fill: parent
                                                    font.family: customFont.name
                                                    minimumPointSize: 5
                                                    font.pointSize: 14
                                                    font.bold: false
                                                    fontSizeMode: Text.Fit
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: "START"
                                                }
                                                palette.buttonText: "#333"
                                                background: Rectangle {
                                                    border.width: btnReset.activeFocus ? 2 : 1
                                                    border.color: "#333"
                                                    gradient: Gradient {
                                                        GradientStop { position: 0 ; color: btnReset.enabled ? (btnReset.pressed ? "#76d11b" : "#dedede") : "#666" }
                                                        GradientStop { position: 1 ; color: btnReset.enabled ? (btnReset.pressed ? "#dedede" : "#76d11b") : "#999" }
                                                    }
                                                }
                                            }

                                            Button{
                                                text: ""
                                                Layout.preferredWidth: parent.width * 0.25
                                                Layout.fillHeight: true
                                                id: btnMasterJobCall
                                                enabled: false
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                padding: 10
                                                contentItem:Label{
                                                    anchors.fill: parent
                                                    minimumPointSize: 5
                                                    font.family: customFont.name
                                                    font.pointSize: 14
                                                    font.bold: false
                                                    fontSizeMode: Text.Fit
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: "JOB CALL"
                                                }
                                                palette.buttonText: "#333"
                                                background: Rectangle {
                                                    border.width: btnMasterJobCall.activeFocus ? 2 : 1
                                                    border.color: "#333"
                                                    gradient: Gradient {
                                                        GradientStop { position: 0 ; color: btnMasterJobCall.enabled ? (btnMasterJobCall.pressed ? "#3688c7" : "#dedede") : "#666" }
                                                        GradientStop { position: 1 ; color: btnMasterJobCall.enabled ? (btnMasterJobCall.pressed ? "#dedede" : "#3688c7") : "#999" }
                                                    }
                                                }
                                            }

                                            Button{
                                                text: ""
                                                Layout.preferredWidth: parent.width * 0.25
                                                Layout.fillHeight: true
                                                id: btnServoOn
                                                enabled: false
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                padding: 10
                                                contentItem:Label{
                                                    anchors.fill: parent
                                                    minimumPointSize: 5
                                                    font.pointSize: 14
                                                    font.family: customFont.name
                                                    font.bold: false
                                                    fontSizeMode: Text.Fit
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: "SERVO ON"
                                                }
                                                palette.buttonText: "#333"
                                                background: Rectangle {
                                                    border.width: btnServoOn.activeFocus ? 2 : 1
                                                    border.color: "#333"
                                                    gradient: Gradient {
                                                        GradientStop { position: 0 ; color: btnServoOn.enabled ? (btnServoOn.pressed ? "#888" : "#dedede") : "#666" }
                                                        GradientStop { position: 1 ; color: btnServoOn.enabled ? (btnServoOn.pressed ? "#dedede" : "#888") : "#999" }
                                                    }
                                                }
                                            }

                                            Button{
                                                text: ""
                                                Layout.preferredWidth: parent.width * 0.25
                                                Layout.fillHeight: true
                                                id: btnStart
                                                enabled: false
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                padding: 10
                                                contentItem:Label{
                                                    anchors.fill: parent
                                                    minimumPointSize: 5
                                                    font.pointSize: 14
                                                    font.bold: false
                                                    font.family: customFont.name
                                                    fontSizeMode: Text.Fit
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: "RUN"
                                                }
                                                palette.buttonText: "#333"
                                                background: Rectangle {
                                                    border.width: btnStart.activeFocus ? 2 : 1
                                                    border.color: "#333"
                                                    gradient: Gradient {
                                                        GradientStop { position: 0 ; color: btnStart.enabled ? (btnStart.pressed ? "#4089d6" : "#dedede") : "#666" }
                                                        GradientStop { position: 1 ; color: btnStart.enabled ? (btnStart.pressed ? "#dedede" : "#4089d6") : "#999" }
                                                    }
                                                }
                                            }
                                        }

                                        Label{
                                            id: lblValidError
                                            visible: (isFullByProduct == false && testRunning == false) || selectionIsValid == false
                                            anchors.fill: parent
                                            minimumPointSize: 5
                                            font.pointSize: 22
                                            font.family: customFont.name
                                            font.bold: true
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: (isFullByProduct == false && testRunning == false) ? "ÜRÜN BEKLENİYOR" : selectionValidMsg
                                            background: Rectangle {
                                                border.width: btnSettings.activeFocus ? 2 : 1
                                                border.color: "#333"
                                                radius: 4
                                                // gradient: Gradient {
                                                //     GradientStop { position: 0 ; color: btnSettings.pressed ? "#326195" : "#dedede" }
                                                //     GradientStop { position: 1 ; color: btnSettings.pressed ? "#dedede" : "#326195" }
                                                // }

                                                ColorAnimation on color { id: animColorWaiting; 
                                                    running:true; to: "#afafaf"; duration: 500;
                                                    onFinished: function(){
                                                        animColorWaiting.to = animColorWaiting.to == '#afafaf' ? '#dedede' : '#afafaf';
                                                        animColorWaiting.start();
                                                    }
                                                }
                                            }
                                            
                                        }
                                    }

                                    // HOLD AND SETTINGS BUTTON
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.fill: parent
                                            spacing: 2

                                            Button{
                                                text: "Ayarlar"
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: parent.height * 0.5
                                                onClicked: openSettings()
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                id:btnSettings
                                                // font.pixelSize: 18
                                                // font.bold: true
                                                padding: 10
                                                contentItem:Label{
                                                    anchors.fill: parent
                                                    anchors.topMargin: 35
                                                    minimumPointSize: 5
                                                    font.family: customFont.name
                                                    font.pointSize: 14
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
                                                    anchors.topMargin: btnSettings.height * 0.5 - 25
                                                    anchors.leftMargin: btnSettings.width * 0.5 - 15
                                                    sourceSize.width: 40
                                                    sourceSize.height: 25
                                                    fillMode: Image.Stretch
                                                    source: "../assets/settings.png"
                                                }
                                            }

                                            Button{
                                                text: ""
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                id: btnEmgStop
                                                onClicked: function(){
                                                    setRobotHold();
                                                }
                                                enabled: true
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                padding: 10
                                                contentItem:Label{
                                                    anchors.fill: parent
                                                    anchors.topMargin: 30
                                                    minimumPointSize: 5
                                                    font.pointSize: 14
                                                    font.family: customFont.name
                                                    font.bold: false
                                                    fontSizeMode: Text.Fit
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: robotHoldStatus == true ? "HOLD OFF" : "HOLD ON"
                                                }
                                                palette.buttonText: "#fff"
                                                background: Rectangle {
                                                    border.width: btnEmgStop.activeFocus ? 2 : 1
                                                    border.color: "#333"
                                                    gradient: Gradient {
                                                        GradientStop { position: 0 ; color: btnEmgStop.enabled ? (btnEmgStop.pressed ? (robotHoldStatus == true ? "green" : "red") : "#dedede") : "#666" }
                                                        GradientStop { position: 1 ; color: btnEmgStop.enabled ? (btnEmgStop.pressed ? "#dedede" : (robotHoldStatus == true ? "green" : "red")) : "#999" }
                                                    }
                                                }

                                                Image {
                                                    anchors.top: btnEmgStop.top
                                                    anchors.left: btnEmgStop.left
                                                    anchors.topMargin: btnEmgStop.height * 0.5 - 30
                                                    anchors.leftMargin: btnEmgStop.width * 0.5 - 20
                                                    sourceSize.width: 50
                                                    sourceSize.height: 35
                                                    fillMode: Image.Stretch
                                                    source: "../assets/stop.png"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SECOND ROW (PRODUCT SECTION GRID)
                    Rectangle{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        Layout.alignment: Qt.AlignTop
                        color: "transparent"//isFullByProduct == true ? "#804cdb2c" : "transparent"
                        border.width: 1
                        border.color: "transparent"
                        radius:5

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
                                    id: rectCmp
                                    color: modelData.isShallow ? "transparent" : "#2396d9"
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
                                        horizontalOffset: 3
                                        verticalOffset: 3
                                        radius: 8.0
                                        samples: 17
                                        color: "#80000000"
                                    }
                                    gradient: modelData.isRunning == false ? gradientProduct : null

                                    // SELECTED SECTION COLOR ANIMATION
                                    ColorAnimation on color { id: animColor; 
                                        running: testRunning == true && modelData.isRunning && modelData.isRunning == true; to: "#4cdb2c"; duration: 500;
                                        onFinished: function(){
                                            animColor.to = animColor.to == '#4cdb2c' ? '#2396d9' : '#4cdb2c';
                                            animColor.start();
                                        }
                                     }

                                    // LINE SCAN ANIMATION
                                    Rectangle{
                                        visible: modelData.isRunning == true && testRunning == true
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.left : parent.left
                                        width: 2
                                        color: "#efefef"
                                        border.width: 1
                                        border.color: "#ffffff"
                                        layer.enabled: true
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 0
                                            radius: 0.0
                                            spread: 5
                                            samples: 17
                                            color: "#80ffffff"
                                        }

                                        Component.onCompleted: function(){
                                            animLine.to = 225 * modelData.sectionWidth - 15;
                                            animLine.start();
                                        }

                                        NumberAnimation on anchors.leftMargin { 
                                            id: animLine
                                            running: false
                                            from: 0
                                            
                                            duration: 1000
                                            onFinished: function(){
                                                animLine.from = animLine.from == (225 * modelData.sectionWidth - 15) ? 0 : (225 * modelData.sectionWidth - 15);
                                                animLine.to = animLine.to == (225 * modelData.sectionWidth - 15) ? 0 : (225 * modelData.sectionWidth - 15);
                                                animLine.start();
                                            }
                                        }
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
                                        font.family: customFont.name
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
                                Layout.preferredHeight: 40
                                color: "#333333"
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
                                            color:"#efefef"
                                            padding: 2
                                            leftPadding: 10
                                            minimumPointSize: 5
                                            font.pointSize: 16
                                            fontSizeMode: Text.Fit
                                            // font.underline: true
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
                                            color:"#efefef"
                                            padding: 2
                                            minimumPointSize: 5
                                            font.pointSize: 16
                                            fontSizeMode: Text.Fit
                                            // font.underline: true
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
                                            color:"#efefef"
                                            padding: 2
                                            minimumPointSize: 5
                                            font.pointSize: 16
                                            fontSizeMode: Text.Fit
                                            // font.underline: true
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

                    // FOURTH ROW (NETWORK STATS & LIVE TEST RESULT STATUS)
                    Rectangle{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 5

                        color: "transparent"
                        
                        RowLayout{
                            anchors.fill: parent
                            
                            // NETWORK STATS
                            Rectangle{
                                Layout.preferredWidth: parent.width * 0.4
                                Layout.fillHeight: true
                                color: "#dfdfdf"
                                border.color: "#888"
                                border.width: 1

                                ColumnLayout{
                                    anchors.fill: parent
                                    spacing: 0

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
                                                padding: 1
                                                leftPadding: 10
                                                font.family: customFont.name
                                                // font.pixelSize: 24
                                                minimumPointSize: 5
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
                                                font.bold: true
                                                text: "Robot Haberleşme"
                                            }

                                            Text {
                                                id: txtRobotStatus
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color:"#32a852"
                                                font.family: customFont.name
                                                padding: 1
                                                rightPadding: 10
                                                minimumPointSize: 5
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
                                                font.bold: true
                                                text: ""
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
                                                padding: 1
                                                leftPadding: 10
                                                font.family: customFont.name
                                                minimumPointSize: 5
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
                                                font.bold: true
                                                text: "Kamera Haberleşme"
                                            }

                                            Text {
                                                id: txtCameraStatus
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color:"#32a852"
                                                font.family: customFont.name
                                                padding: 1
                                                rightPadding: 10
                                                minimumPointSize: 5
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
                                                font.bold: true
                                                text: ""
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
                                                padding: 1
                                                leftPadding: 10
                                                minimumPointSize: 5
                                                font.family: customFont.name
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
                                                font.bold: true
                                                text: "Acil Devresi"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color: "#32a852"
                                                padding: 1
                                                rightPadding: 10
                                                minimumPointSize: 5
                                                font.family: customFont.name
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
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
                                                padding: 1
                                                leftPadding: 10
                                                minimumPointSize: 5
                                                font.family: customFont.name
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
                                                font.bold: true
                                                text: "Yazıcı"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                                color: "#32a852"
                                                padding: 1
                                                rightPadding: 10
                                                minimumPointSize: 5
                                                font.family: customFont.name
                                                font.pointSize: 12
                                                fontSizeMode: Text.Fit
                                                font.bold: true
                                                text: ": OK"
                                            }
                                        }
                                    }
                                }
                            }

                            // LIVE RESULT STATUS INFO
                            Rectangle{
                                // Layout.fillWidth: true
                                Layout.preferredWidth: parent.width * 0.4
                                Layout.fillHeight: true
                                color: "#dfdfdf"
                                border.color: "#888"
                                border.width: 1

                                // gradient: Gradient {
                                //     GradientStop { position: 0.0; color: "#9dd2fa" }
                                //     GradientStop { position: 1.0; color: "#326195" }
                                // }

                                RowLayout{
                                    anchors.fill: parent

                                    // TEST STATUS COUNTS
                                    Rectangle{
                                        Layout.preferredWidth: parent.width / 2
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        ColumnLayout{
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            height: parent.height * 0.5
                                            anchors.topMargin: 2
                                            spacing:0

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
                                                        color:"#333"
                                                        padding: 1
                                                        font.family: customFont.name
                                                        leftPadding: 10
                                                        minimumPointSize: 5
                                                        font.pointSize: 12
                                                        fontSizeMode: Text.Fit
                                                        font.bold: true
                                                        text: "Toplam Test"
                                                    }

                                                    Text {
                                                        id: txtTotalTestCount
                                                        Layout.preferredWidth: parent.width * 0.4
                                                        horizontalAlignment: Text.AlignLeft
                                                        color:"#333"
                                                        padding: 1
                                                        leftPadding: 10
                                                        font.family: customFont.name
                                                        minimumPointSize: 5
                                                        font.pointSize: 12
                                                        fontSizeMode: Text.Fit
                                                        font.bold: true
                                                        text: ": "
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
                                                        color:"#333"
                                                        padding: 1
                                                        leftPadding: 10
                                                        minimumPointSize: 5
                                                        font.pointSize: 12
                                                        font.family: customFont.name
                                                        fontSizeMode: Text.Fit
                                                        font.bold: true
                                                        text: "Hatalı Adet"
                                                    }

                                                    Text {
                                                        id: txtTotalFaultCount
                                                        Layout.preferredWidth: parent.width * 0.4
                                                        horizontalAlignment: Text.AlignLeft
                                                        color:"#c70c12"
                                                        padding: 1
                                                        leftPadding: 10
                                                        font.family: customFont.name
                                                        minimumPointSize: 5
                                                        font.pointSize: 12
                                                        fontSizeMode: Text.Fit
                                                        font.bold: true
                                                        text: ": "
                                                    }
                                                }
                                            }

                                             // TOTAL OK COUNT
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
                                                        color:"#333"
                                                        padding: 1
                                                        leftPadding: 10
                                                        minimumPointSize: 5
                                                        font.pointSize: 12
                                                        font.family: customFont.name
                                                        fontSizeMode: Text.Fit
                                                        font.bold: true
                                                        text: "Hatasız Adet"
                                                    }

                                                    Text {
                                                        id: txtTotalOkCount
                                                        Layout.preferredWidth: parent.width * 0.4
                                                        horizontalAlignment: Text.AlignLeft
                                                        color:"#32a852"
                                                        padding: 1
                                                        leftPadding: 10
                                                        font.family: customFont.name
                                                        minimumPointSize: 5
                                                        font.pointSize: 12
                                                        fontSizeMode: Text.Fit
                                                        font.bold: true
                                                        text: ": "
                                                    }
                                                }
                                            }

                                            // VIEW BUFFER
                                            Rectangle{
                                                color: "transparent"
                                                Layout.fillHeight: true
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    // OEE STATUS
                                    Rectangle{
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        CircularSlider {
                                            id: oeeSlider
                                            anchors.fill: parent
                                            anchors.topMargin: 5
                                            value: 0
                                            startAngle: 40
                                            endAngle: 320
                                            rotation: 180
                                            trackWidth: 20
                                            progressWidth: 10
                                            minValue: 0
                                            maxValue: 100
                                            progressColor: "#2396d9"
                                            trackColor: "#333"
                                            capStyle: Qt.FlatCap

                                            Behavior on value {
                                                NumberAnimation {
                                                    duration: 500
                                                }
                                            }

                                            handle: Rectangle {
                                                transform: Translate {
                                                    x: (oeeSlider.handleWidth - width) / 2
                                                    y: oeeSlider.handleHeight / 2
                                                }

                                                width: 3
                                                height: oeeSlider.height / 2
                                                color: "black"
                                                radius: width / 2
                                                antialiasing: true
                                                layer.enabled: true
                                                layer.effect: DropShadow {
                                                    horizontalOffset: 3
                                                    verticalOffset: 3
                                                    radius: 8.0
                                                    samples: 17
                                                    color: "#80000000"
                                                }

                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: "#9dd2fa" }
                                                    GradientStop { position: 1.0; color: "#326195" }
                                                }
                                            }

                                            Label {
                                                anchors.centerIn: parent
                                                anchors.verticalCenterOffset: -10
                                                rotation: 180
                                                font.pointSize: 12
                                                color: "#333"
                                                // style: Text.Outline
                                                // styleColor:'#000'
                                                text: 'OEE'
                                            }

                                            Label {
                                                anchors.centerIn: parent
                                                anchors.verticalCenterOffset: -30
                                                rotation: 180
                                                // font.pointSize: 20
                                                minimumPointSize: 5
                                                font.pointSize: 12
                                                font.bold: true
                                                fontSizeMode: Text.Fit
                                                color: "#2396d9"
                                                // style: Text.Outline
                                                // styleColor:'#2396d9'
                                                text: '%' + Number(oeeSlider.value).toFixed()
                                            }
                                        }                                     
                                    }
                                }
                            }

                            // LIVE LAST TEST STATUS
                            Rectangle{
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "black"

                                border.color: "#888"
                                border.width: 1

                                // gradient: Gradient {
                                //     GradientStop { position: 0 ; color: "#dedede" }
                                //     GradientStop { position: 1 ; color: "#AAA" }
                                // }

                                AnimatedImage{
                                    visible: lastTestStatus == 0
                                    source: "../assets/waiting_for_test.webp"
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                }

                                Image {
                                    visible: lastTestStatus > 0
                                    id: resultImage
                                    anchors.centerIn: parent
                                    anchors.margins: 5
                                    sourceSize.height: 80
                                    fillMode: Image.PreserveAspectFit
                                    source: lastTestStatus == 0 ? '../assets/waiting_for_test.webp' : (lastTestStatus == 1 ? '../assets/ok.png' : '../assets/error.png')
                                    // RotationAnimator {
                                    //     id: resultImageRotation
                                    //     target: resultImage;
                                    //     from: 0;
                                    //     to: 360;
                                    //     duration: 3000
                                    //     running: lastTestStatus == 0
                                    //     onFinished: function(){
                                    //         if (lastTestStatus == 0)
                                    //             resultImageRotation.start();
                                    //     }
                                    // }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}