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

    property var modelObject: new Object({ id:0, sections: [], recipes: [], steps: [] })
    property var sectionModel: new Object({ id:0 })
    property var recipeModel: new Object({ id:0 })
    property var stepModel: new Object({ id:0 })

    FileDialog {
        id: fileDialog
        title: "Lütfen dizin seçiniz"
        selectMultiple: false
        selectFolder: true
        onAccepted: {
            txtRecipeImagePath.text = fileDialog.fileUrl;
            txtRecipeImagePath.text = txtRecipeImagePath.text.replace('file://', '');
            fileDialog.close();
        }
        onRejected: {
            fileDialog.close();
        }
    }

    anchors.centerIn: parent
    width: parent.width * 0.8
    height: parent.height * 0.8

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
            backend.requestProductInfo(recordId);
        }
        else{
            txtProductCode.text = '';
            txtProductName.text = '';
            txtGridWidth.text = '5';
            txtGridHeight.text = '4';
            bindGridSchema();
        }
    }

    function saveModel(){
        waitingIcon.visible = true;
        delay(200, function(){
            backend.saveProduct(JSON.stringify({
                id: recordId,
                productNo: txtProductCode.text,
                productName: txtProductName.text,
                imagePath: 'test.png',
                isActive: true,
                gridWidth: parseInt(txtGridWidth.text),
                gridHeight: parseInt(txtGridHeight.text),
                sections: modelObject.sections,
                recipes: modelObject.recipes,
                steps: modelObject.steps,
            }));
        });
    }

    function deleteModel(){
        waitingIcon.visible = true;
        delay(200, function(){
            backend.deleteProduct(recordId);
        });
    }

    /* BEGIN SECTION FUNCTIONS */
    function newSection(){
        sectionModel = { id:0 };
        txtSectionAreaNo.text = '';
        txtSectionHeight.text = '1';
        txtSectionName.text = '';
        txtSectionOrder.text = '';
        txtSectionPosX.text = '0';
        txtSectionPosY.text = '0';
        txtSectionWidth.text = '1';
        txtSectionName.focus = true;
    }

    function showSection(id, name){
        sectionModel = modelObject.sections.find(d => (d.id > 0 && d.id == id) || d.sectionName == name);
        if (!sectionModel)
            newSection();
        else {
            txtSectionAreaNo.text = sectionModel.areaNo.toString();
            txtSectionHeight.text = sectionModel.sectionHeight.toString();
            txtSectionName.text = sectionModel.sectionName;
            txtSectionOrder.text = sectionModel.orderNo.toString();
            txtSectionPosX.text = sectionModel.posX.toString();
            txtSectionPosY.text = sectionModel.posY.toString();
            txtSectionWidth.text = sectionModel.sectionWidth.toString();
            txtSectionName.focus = true;
        }
    }

    function saveSection(){
        if (sectionModel){
            sectionModel.sectionName = txtSectionName.text;
            sectionModel.areaNo = parseInt(txtSectionAreaNo.text);
            sectionModel.orderNo = parseInt(txtSectionOrder.text);
            sectionModel.posX = parseInt(txtSectionPosX.text);
            sectionModel.posY = parseInt(txtSectionPosY.text);
            sectionModel.sectionWidth = parseInt(txtSectionWidth.text);
            sectionModel.sectionHeight = parseInt(txtSectionHeight.text);
        }

        if (!modelObject.sections.includes(sectionModel))
            modelObject.sections.push(sectionModel);

        saveModel();
        // bindSectionList();
    }

    function deleteSection(){
        if (modelObject && sectionModel
            && modelObject.sections && modelObject.sections.includes(sectionModel)){
                modelObject.sections = modelObject.sections.filter(d => d != sectionModel);
                saveModel();
                // bindSectionList();
            }
    }
    /* END SECTION FUNCTIONS */

    /* BEGIN RECIPE FUNCTIONS */
    function newRecipe(){
        recipeModel = { id:0 };
        txtRecipeCode.text = '';
        txtRecipeCamResultByteIndex.text = '';
        txtRecipeRbFromReadyToStart.text = '';
        txtRecipeRbFromScanningFinished.text = '';
        txtRecipeRbToRecipeStarted.text = '';
        txtRecipeRbToStartScan.text = '';
        txtRecipeCode.focus = true;
    }

    function showRecipe(id, code){
        recipeModel = modelObject.recipes.find(d => (d.id > 0 && d.id == id) || d.recipeCode == code);
        if (!recipeModel)
            newRecipe();
        else{
            txtRecipeCode.text = recipeModel.recipeCode;
            txtRecipeCamResultByteIndex.text = (recipeModel.camResultFormat ?? '');
            txtRecipeRbFromReadyToStart.text = recipeModel.rbFromReadyToStart;
            txtRecipeRbFromScanningFinished.text = recipeModel.rbFromScanningFinished;
            txtRecipeRbToRecipeStarted.text = recipeModel.rbToRecipeStarted;
            txtRecipeRbToStartScan.text = recipeModel.rbToStartScanning;
            txtRecipeStartDelay.text = (recipeModel.startDelay ?? 0).toString();
            txtRecipeImagePath.text = (recipeModel.imageDir ?? '');
            txtRecipeCode.focus = true;
        }
    }

    function saveRecipe(){
        if (recipeModel){
            recipeModel.recipeCode = txtRecipeCode.text;
            recipeModel.camResultFormat = txtRecipeCamResultByteIndex.text;
            recipeModel.rbFromReadyToStart = txtRecipeRbFromReadyToStart.text;
            recipeModel.rbFromScanningFinished = txtRecipeRbFromScanningFinished.text;
            recipeModel.rbToRecipeStarted = txtRecipeRbToRecipeStarted.text;
            recipeModel.rbToStartScanning = txtRecipeRbToStartScan.text;
            recipeModel.imageDir = txtRecipeImagePath.text;

            if (txtRecipeStartDelay.text.length > 0)
                recipeModel.startDelay = parseInt(txtRecipeStartDelay.text);
            else
                recipeModel.startDelay = null;
        }

        if (!modelObject.recipes.includes(recipeModel))
            modelObject.recipes.push(recipeModel);

        saveModel();
    }

    function deleteRecipe(){
        if (modelObject && recipeModel
            && modelObject.recipes && modelObject.recipes.includes(recipeModel)){
                modelObject.recipes = modelObject.recipes.filter(d => d != recipeModel);
                saveModel();
                // bindSectionList();
            }
    }

    function showFileDialog(){
        fileDialog.open();
    }
    /* END RECIPE FUNCTIONS */

    /* BEGIN STEP FUNCTIONS */
    function newStep(){
        stepModel = { id:0 };
        txtStepTestName.text = '';
        txtStepOrderNo.text = '0';
        cmbStepRecipe.currentIndex = -1;
        cmbStepSection.currentIndex = -1;
        txtStepTestName.focus = true;
    }

    function showStep(id, name){
        stepModel = modelObject.steps.find(d => (d.id > 0 && d.id == id) || d.testName == name);
        if (!stepModel)
            newStep();
        else{
            txtStepTestName.text = stepModel.testName;
            txtStepOrderNo.text = (stepModel.orderNo ?? 0).toString();

            if (stepModel.camRecipeId && stepModel.camRecipeId > 0){
                var foundObj = modelObject.recipes.find(d => d.id == stepModel.camRecipeId);
                
                if (foundObj)
                    cmbStepRecipe.currentIndex = modelObject.recipes.indexOf(foundObj);
            }
            else
                cmbStepRecipe.currentIndex = -1;

            if (stepModel.sectionId && stepModel.sectionId > 0){
                var foundObj = modelObject.sections.find(d => d.id == stepModel.sectionId);
                
                if (foundObj)
                    cmbStepSection.currentIndex = modelObject.sections.indexOf(foundObj);
            }
            else
                cmbStepSection.currentIndex = -1;

            txtStepTestName.focus = true;
        }
    }

    function saveStep(){
        if (stepModel){
            stepModel.testName = txtStepTestName.text;
            stepModel.orderNo = parseInt(txtStepOrderNo.text);
            
            if (cmbStepRecipe.currentIndex > -1)
                stepModel.camRecipeId = parseInt(cmbStepRecipe.currentValue);
            else
                stepModel.camRecipeId = null;

            if (cmbStepSection.currentIndex > -1)
                stepModel.sectionId = parseInt(cmbStepSection.currentValue);
            else
                stepModel.sectionId = null;
        }

        if (!modelObject.steps.includes(stepModel))
            modelObject.steps.push(stepModel);

        saveModel();
    }

    function deleteStep(){
        if (modelObject && stepModel
            && modelObject.steps && modelObject.steps.includes(stepModel)){
                modelObject.steps = modelObject.steps.filter(d => d != stepModel);
                saveModel();
                // bindSectionList();
            }
    }
    /* END STEP FUNCTIONS */

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
            var w = parseInt(txtGridWidth.text);
            var h = parseInt(txtGridHeight.text);

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

            if (modelObject && modelObject.sections){
                modelObject.sections.forEach(d => {
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
        } catch (error) {
        }
    }

    function bindSectionList(){
        if (modelObject.sections)
            rptSections.model = modelObject.sections.sort((a,b) => a.orderNo - b.orderNo);
        bindGridSchema();
    }

    function bindCamRecipeList(){
        rptRecipes.model = modelObject.recipes;
    }

    function bindStepsList(){
        if (modelObject.steps)
            rptSteps.model = modelObject.steps.sort((a,b) => a.orderNo - b.orderNo);
    }

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onGetProductInfo(productInfo){
            const data = JSON.parse(productInfo);
            if (data){
                txtProductCode.text = data.productNo;
                txtProductName.text = data.productName;
                txtGridWidth.text = (data.gridWidth ?? 0).toString();
                txtGridHeight.text = (data.gridHeight ?? 0).toString();
                modelObject = data;

                bindSectionList();
                bindCamRecipeList();
                bindStepsList();

                if (modelObject.sections){
                    cmbStepSection.model = modelObject.sections.map(d => {
                        return {
                            text: d.sectionName,
                            value: d.id,
                        }
                    });
                }

                if (modelObject.recipes){
                    cmbStepRecipe.model = modelObject.recipes.map(d => {
                        return {
                            text: d.recipeCode,
                            value: d.id,
                        }
                    });
                }

                cmbStepSection.currentIndex = -1;
                cmbStepSection.currentIndex = -1;
            }
        }

        function onSaveProductFinished(saveResult){
            waitingIcon.visible = false;
            var resultData = JSON.parse(saveResult);
            if (resultData){
                if (resultData.Result){
                    recordId = resultData.RecordId
                    bindModel();
                    backend.broadcastProductListRefresh();
                }
            }
        }

        function onDeleteProductFinished(saveResult){
            waitingIcon.visible = false;
            var resultData = JSON.parse(saveResult);
            if (resultData){
                if (resultData.Result){
                    backend.broadcastProductListRefresh();
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
        text: "Bu ürünü silmek istediğinizden emin misiniz?"
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
                        text: "Ürün Tanımı"
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

                // LEFT FORM AREA
                Rectangle{
                    Layout.preferredWidth: parent.width * 0.3
                    Layout.fillHeight: true
                    border.color: "#afafaf"
                    border.width: 1
                    radius:5
                    color: "#efefef"

                    ColumnLayout{
                        anchors.fill: parent

                        // PRODUCT CODE FIELD
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
                                    text:'Ürün Kodu'
                                    font.pixelSize: 16
                                }

                                TextField {
                                    id: txtProductCode
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    font.pixelSize: 16
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

                        // PRODUCT NAME FIELD
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
                                    text:'Ürün Adı'
                                    font.pixelSize: 16
                                }

                                TextField {
                                    id: txtProductName
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    font.pixelSize: 16
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

                        // VIEW BUFFER RECT
                        Rectangle{
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                        }
                    }
                }

                // RIGHT FORM AREA
                Rectangle{
                    Layout.preferredWidth: parent.width * 0.7
                    Layout.fillHeight: true
                    color: "transparent"

                    ColumnLayout{
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        spacing: 0

                        // TAB PANEL
                        TabBar{
                            id: tabBar
                            Layout.fillWidth: true

                            TabButton{
                                text: "Bölgeler"
                                icon.source: "../assets/area.png"
                                font.pixelSize: 18
                                background: Rectangle {
                                    color: tabBar.currentIndex == 0 ? "#c8cacc" : "black"
                                }
                                onClicked: function(){
                                    if (tabContent.currentItem != sectionTab){
                                        bindSectionList();
                                        tabContent.replace(tabContent.currentItem, sectionTab);
                                    }
                                }
                            }

                            TabButton{
                                text: "Reçeteler"
                                icon.source: "../assets/camera.png"
                                font.pixelSize: 18
                                background: Rectangle {
                                    color: tabBar.currentIndex == 1 ? "#c8cacc" : "black"
                                }
                                onClicked: function(){
                                    if (tabContent.currentItem != recipeTab){
                                        bindCamRecipeList();
                                        tabContent.replace(tabContent.currentItem, recipeTab);
                                    }
                                }
                            }

                            TabButton{
                                text: "Test Adımları"
                                icon.source: "../assets/checklist.png"
                                font.pixelSize: 18
                                background: Rectangle {
                                    color: tabBar.currentIndex == 2 ? "#c8cacc" : "black"
                                }
                                onClicked: function(){
                                    if (tabContent.currentItem != stepsTab){
                                        bindStepsList();
                                        tabContent.replace(tabContent.currentItem, stepsTab);
                                    }
                                }
                            }
                        }

                        StackView{
                            id: tabContent
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 5
                            Layout.bottomMargin: 5

                            replaceEnter: Transition {
                                PropertyAnimation {
                                    property: "opacity"
                                    from: 0
                                    to:1
                                    duration: 200
                                }
                            }
                            replaceExit: Transition {
                                PropertyAnimation {
                                    property: "opacity"
                                    from: 1
                                    to:0
                                    duration: 200
                                }
                            }

                            initialItem: sectionTab

                            // SECTIONS TAB CONTENT
                            Item {
                                id: sectionTab
                                Rectangle{ 
                                    anchors.fill: parent
                                    color: "transparent"

                                    ColumnLayout{
                                        anchors.fill: parent
                                        spacing: 0

                                        // PRODUCT GRID SCHEMA
                                        Rectangle{
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 80
                                            color: "transparent"

                                            RowLayout{
                                                anchors.fill: parent
                                                spacing: 0

                                                // GRID PROPERTIES
                                                Rectangle{
                                                    Layout.preferredWidth: 75
                                                    Layout.fillHeight: true
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent
                                                        spacing: 0

                                                        // DIM WIDTH
                                                        Rectangle{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 40
                                                            Layout.alignment: Qt.AlignTop
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.fillHeight: true
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'W'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 14
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtGridWidth
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
                                                                    onTextChanged: bindGridSchema()
                                                                    background: Rectangle {
                                                                        radius: 5
                                                                        border.color: parent.focus ? "#326195" : "#888"
                                                                        border.width: 1
                                                                        color: parent.focus ? "#efefef" : "transparent"
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // DIM HEIGHT
                                                        Rectangle{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 40
                                                            Layout.alignment: Qt.AlignTop
                                                            Layout.topMargin: 15
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.fillHeight: true
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'H'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 14
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtGridHeight
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    onTextChanged: bindGridSchema()
                                                                    padding: 2
                                                                    background: Rectangle {
                                                                        radius: 5
                                                                        border.color: parent.focus ? "#326195" : "#888"
                                                                        border.width: 1
                                                                        color: parent.focus ? "#efefef" : "transparent"
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // PRODUCT GRID PANEL
                                                Rectangle{
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    Layout.margins: 10
                                                    color: "transparent"

                                                    GridLayout {
                                                        id: gridProduct
                                                        anchors.fill: parent
                                                        columnSpacing: 2
                                                        rowSpacing: 2

                                                        Repeater{
                                                            id: rptGridProduct
                                                            
                                                            Rectangle{
                                                                color: modelData.isShallow ? "transparent" : 
                                                                    (( (modelData.id > 0 && modelData.id == sectionModel.id) || modelData.sectionName == sectionModel.sectionName) ? "#b3fa50" : "#9dd2fa")
                                                                border.width: 1
                                                                border.color: "#afafaf"
                                                                Layout.column: modelData.posX
                                                                Layout.row: modelData.posY
                                                                Layout.rowSpan: modelData.sectionHeight
                                                                Layout.columnSpan: modelData.sectionWidth
                                                                Layout.fillWidth: true
                                                                Layout.preferredHeight: parent.height / gridProduct.rows * modelData.sectionHeight
                                                                //Layout.fillHeight: true

                                                                MouseArea{
                                                                    anchors.fill: parent
                                                                    onClicked: function(){
                                                                        if (modelData && (modelData.id || modelData.sectionName))
                                                                            showSection(modelData.id, modelData.sectionName);
                                                                    }
                                                                }

                                                                Label{
                                                                    anchors.centerIn: parent
                                                                    text: modelData.sectionName ?? ''
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // SECTION LIST & EDIT
                                        Rectangle{
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: "transparent"

                                            RowLayout{
                                                anchors.fill: parent
                                                spacing: 0
    
                                                // SECTION LIST
                                                Rectangle{
                                                    Layout.preferredWidth: parent.width * 0.7
                                                    Layout.fillHeight: true
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        // FILTER & BUTTONS
                                                        Rectangle{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 40
                                                            Layout.alignment: Qt.AlignTop
                                                            color: "transparent"

                                                            RowLayout{
                                                                anchors.fill: parent

                                                                Button{
                                                                    text: "Yeni Bölge"
                                                                    onClicked: function(){
                                                                        newSection();
                                                                    }
                                                                    Layout.alignment: Qt.AlignRight
                                                                    id:btnNewSection
                                                                    font.pixelSize: 16
                                                                    font.bold: true
                                                                    padding: 5
                                                                    leftPadding: 30
                                                                    palette.buttonText: "#333"
                                                                    background: Rectangle {
                                                                        border.width: btnNewSection.activeFocus ? 2 : 1
                                                                        border.color: "#326195"
                                                                        radius: 4
                                                                        gradient: Gradient {
                                                                            GradientStop { position: 0 ; color: btnNewSection.pressed ? "#326195" : "#dedede" }
                                                                            GradientStop { position: 1 ; color: btnNewSection.pressed ? "#dedede" : "#326195" }
                                                                        }
                                                                    }

                                                                    Image {
                                                                        anchors.top: btnNewSection.top
                                                                        anchors.left: btnNewSection.left
                                                                        anchors.topMargin: 5
                                                                        anchors.leftMargin: 5
                                                                        sourceSize.width: 40
                                                                        sourceSize.height: 20
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
                                                                        minimumPointSize: 5
                                                                        font.pointSize: 14
                                                                        fontSizeMode: Text.Fit
                                                                        font.underline: true
                                                                        font.bold: true
                                                                        text: "Sıra No"
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
                                                                        minimumPointSize: 5
                                                                        font.pointSize: 14
                                                                        fontSizeMode: Text.Fit
                                                                        font.underline: true
                                                                        font.bold: true
                                                                        text: "Bölge Adı"
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
                                                                        minimumPointSize: 5
                                                                        font.pointSize: 14
                                                                        fontSizeMode: Text.Fit
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
                                                                        id: rptSections
                                                                        
                                                                        Rectangle {
                                                                            Layout.fillWidth: true
                                                                            Layout.preferredHeight: 20
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
                                                                                        GradientStop { position: 0.0; color: 
                                                                                            ( (modelData.id > 0 && modelData.id == sectionModel.id) || modelData.sectionName == sectionModel.sectionName) ? "#7eb038" : "#326195" }
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
                                                                                        minimumPointSize: 5
                                                                                        font.pointSize: 10
                                                                                        fontSizeMode: Text.Fit
                                                                                        font.bold: true
                                                                                        text: (modelData.orderNo ?? '')
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
                                                                                        minimumPointSize: 5
                                                                                        font.pointSize: 10
                                                                                        fontSizeMode: Text.Fit
                                                                                        text: (modelData.sectionName ?? '')
                                                                                    }
                                                                                }

                                                                                Rectangle{
                                                                                    Layout.preferredWidth: 100
                                                                                    Layout.fillHeight: true
                                                                                    color: "transparent"

                                                                                    Button{
                                                                                        onClicked: showSection(modelData.id, modelData.sectionName)
                                                                                        width: 30
                                                                                        height: parent.height
                                                                                        anchors.top: parent.top
                                                                                        anchors.topMargin: 0
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
                                                                                            anchors.topMargin: 2
                                                                                            anchors.leftMargin: 8
                                                                                            sourceSize.width: 30
                                                                                            sourceSize.height: 15
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

                                                // SECTION FORM
                                                Rectangle{
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    Layout.margins: 5
                                                    border.width: 1
                                                    border.color: "#afafaf"
                                                    radius: 5
                                                    color: "#efefef"

                                                    ColumnLayout{
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 5
                                                        anchors.rightMargin: 5
                                                        anchors.topMargin: 10
                                                        spacing: 0

                                                        // SECTION NAME FIELD
                                                        Rectangle{
                                                            Layout.preferredHeight: 40
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignTop
                                                            Layout.margins: 0
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 12
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'Bölge Adı'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 14
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtSectionName
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
                                                                    background: Rectangle {
                                                                        radius: 5
                                                                        border.color: parent.focus ? "#326195" : "#888"
                                                                        border.width: 1
                                                                        color: parent.focus ? "#efefef" : "#ffffff"
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // SECTION AREA NO FIELD
                                                        Rectangle{
                                                            Layout.preferredHeight: 40
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignTop
                                                            Layout.margins: 0
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 12
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'Bölge No'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 14
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtSectionAreaNo
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
                                                                    background: Rectangle {
                                                                        radius: 5
                                                                        border.color: parent.focus ? "#326195" : "#888"
                                                                        border.width: 1
                                                                        color: parent.focus ? "#efefef" : "#ffffff"
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // SECTION ORDER NO FIELD
                                                        Rectangle{
                                                            Layout.preferredHeight: 40
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignTop
                                                            Layout.margins: 0
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 12
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'Sıra No'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 14
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtSectionOrder
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
                                                                    background: Rectangle {
                                                                        radius: 5
                                                                        border.color: parent.focus ? "#326195" : "#888"
                                                                        border.width: 1
                                                                        color: parent.focus ? "#efefef" : "#ffffff"
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // SECTION POSITION (X,Y)
                                                        Rectangle{
                                                            Layout.preferredHeight: 40
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignTop
                                                            Layout.margins: 0
                                                            color: "transparent"

                                                            RowLayout{
                                                                anchors.fill: parent

                                                                // POS X FIELD
                                                                Rectangle{
                                                                    Layout.fillWidth: true
                                                                    Layout.fillHeight: true
                                                                    Layout.alignment: Qt.AlignTop
                                                                    color: "transparent"

                                                                    ColumnLayout{
                                                                        anchors.fill: parent

                                                                        Label{
                                                                            Layout.fillWidth: true
                                                                            Layout.preferredHeight: 12
                                                                            Layout.alignment: Qt.AlignTop
                                                                            horizontalAlignment: Text.AlignLeft
                                                                            text:'X'
                                                                            minimumPointSize: 5
                                                                            font.pointSize: 14
                                                                            fontSizeMode: Text.Fit
                                                                        }

                                                                        TextField {
                                                                            id: txtSectionPosX
                                                                            Layout.fillHeight: true
                                                                            Layout.fillWidth: true
                                                                            font.pixelSize: 9
                                                                            padding: 2
                                                                            background: Rectangle {
                                                                                radius: 5
                                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                                border.width: 1
                                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                                            }
                                                                        }
                                                                    }
                                                                }

                                                                // POS Y FIELD
                                                                Rectangle{
                                                                    Layout.fillWidth: true
                                                                    Layout.fillHeight: true
                                                                    Layout.alignment: Qt.AlignTop
                                                                    color: "transparent"

                                                                    ColumnLayout{
                                                                        anchors.fill: parent

                                                                        Label{
                                                                            Layout.fillWidth: true
                                                                            Layout.preferredHeight: 12
                                                                            Layout.alignment: Qt.AlignTop
                                                                            horizontalAlignment: Text.AlignLeft
                                                                            text:'Y'
                                                                            minimumPointSize: 5
                                                                            font.pointSize: 14
                                                                            fontSizeMode: Text.Fit
                                                                        }

                                                                        TextField {
                                                                            id: txtSectionPosY
                                                                            Layout.fillHeight: true
                                                                            Layout.fillWidth: true
                                                                            font.pixelSize: 9
                                                                            padding: 2
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

                                                        // SECTION DIMS (W,H)
                                                        Rectangle{
                                                            Layout.preferredHeight: 40
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignTop
                                                            Layout.margins: 0
                                                            color: "transparent"

                                                            RowLayout{
                                                                anchors.fill: parent

                                                                // WIDTH FIELD
                                                                Rectangle{
                                                                    Layout.fillWidth: true
                                                                    Layout.fillHeight: true
                                                                    Layout.alignment: Qt.AlignTop
                                                                    color: "transparent"

                                                                    ColumnLayout{
                                                                        anchors.fill: parent

                                                                        Label{
                                                                            Layout.fillWidth: true
                                                                            Layout.preferredHeight: 12
                                                                            Layout.alignment: Qt.AlignTop
                                                                            horizontalAlignment: Text.AlignLeft
                                                                            text:'W'
                                                                            minimumPointSize: 5
                                                                            font.pointSize: 14
                                                                            fontSizeMode: Text.Fit
                                                                        }

                                                                        TextField {
                                                                            id: txtSectionWidth
                                                                            Layout.fillHeight: true
                                                                            Layout.fillWidth: true
                                                                            font.pixelSize: 9
                                                                            padding: 2
                                                                            background: Rectangle {
                                                                                radius: 5
                                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                                border.width: 1
                                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                                            }
                                                                        }
                                                                    }
                                                                }

                                                                // HEIGHT FIELD
                                                                Rectangle{
                                                                    Layout.fillWidth: true
                                                                    Layout.fillHeight: true
                                                                    Layout.alignment: Qt.AlignTop
                                                                    color: "transparent"

                                                                    ColumnLayout{
                                                                        anchors.fill: parent

                                                                        Label{
                                                                            Layout.fillWidth: true
                                                                            Layout.preferredHeight: 12
                                                                            Layout.alignment: Qt.AlignTop
                                                                            horizontalAlignment: Text.AlignLeft
                                                                            text:'H'
                                                                            minimumPointSize: 5
                                                                            font.pointSize: 14
                                                                            fontSizeMode: Text.Fit
                                                                        }

                                                                        TextField {
                                                                            id: txtSectionHeight
                                                                            Layout.fillHeight: true
                                                                            Layout.fillWidth: true
                                                                            font.pixelSize: 9
                                                                            padding: 2
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
                                                        
                                                        // ACTION BUTTONS
                                                        Rectangle{
                                                            Layout.preferredHeight: 30
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignTop
                                                            Layout.margins: 2
                                                            color: "transparent"

                                                            RowLayout{
                                                                anchors.fill: parent
                                                                spacing: 10

                                                                // SECTION SAVE BUTTON
                                                                Button{
                                                                    onClicked: function(){
                                                                        saveSection();
                                                                    }
                                                                    Layout.fillWidth: true
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
                                                                        sourceSize.width: 40
                                                                        sourceSize.height: 20
                                                                        fillMode: Image.Stretch
                                                                        source: "../assets/save.png"
                                                                    }
                                                                }

                                                                // SECTION DELETE BUTTON
                                                                Button{
                                                                    onClicked: function(){
                                                                        deleteSection();
                                                                    }
                                                                    Layout.fillWidth: true
                                                                    Layout.fillHeight: true
                                                                    padding: 5
                                                                    background: Rectangle {
                                                                        color: "#e6210b"
                                                                        border.width: 1
                                                                        border.color: "#333"
                                                                        radius: 4
                                                                    }
                                                                    Image {
                                                                        anchors.centerIn: parent
                                                                        sourceSize.width: 40
                                                                        sourceSize.height: 20
                                                                        fillMode: Image.Stretch
                                                                        source: "../assets/delete.png"
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
                            }

                            // RECIPES TAB CONTENT
                            Item{
                                id: recipeTab
                                visible: tabContent.currentItem == recipeTab
                                Rectangle{ 
                                    anchors.fill: parent
                                    color:"transparent"

                                    RowLayout{
                                        anchors.fill: parent
                                        spacing: 0

                                        // RECIPE LIST
                                        Rectangle{
                                            Layout.preferredWidth: parent.width * 0.7
                                            Layout.fillHeight: true
                                            color: "transparent"

                                            ColumnLayout{
                                                anchors.fill: parent

                                                // FILTER & BUTTONS
                                                Rectangle{
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    Layout.alignment: Qt.AlignTop
                                                    color: "transparent"

                                                    RowLayout{
                                                        anchors.fill: parent

                                                        Button{
                                                            text: "Yeni Reçete"
                                                            onClicked: function(){
                                                                newRecipe();
                                                            }
                                                            Layout.alignment: Qt.AlignRight
                                                            id:btnNewRecipe
                                                            font.pixelSize: 16
                                                            font.bold: true
                                                            padding: 5
                                                            leftPadding: 30
                                                            palette.buttonText: "#333"
                                                            background: Rectangle {
                                                                border.width: btnNewRecipe.activeFocus ? 2 : 1
                                                                border.color: "#326195"
                                                                radius: 4
                                                                gradient: Gradient {
                                                                    GradientStop { position: 0 ; color: btnNewRecipe.pressed ? "#326195" : "#dedede" }
                                                                    GradientStop { position: 1 ; color: btnNewRecipe.pressed ? "#dedede" : "#326195" }
                                                                }
                                                            }

                                                            Image {
                                                                anchors.top: btnNewRecipe.top
                                                                anchors.left: btnNewRecipe.left
                                                                anchors.topMargin: 5
                                                                anchors.leftMargin: 5
                                                                sourceSize.width: 40
                                                                sourceSize.height: 20
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
                                                            Layout.preferredWidth: parent.width - 100
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
                                                                minimumPointSize: 5
                                                                font.pointSize: 14
                                                                fontSizeMode: Text.Fit
                                                                font.underline: true
                                                                font.bold: true
                                                                text: "Reçete No"
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
                                                                minimumPointSize: 5
                                                                font.pointSize: 14
                                                                fontSizeMode: Text.Fit
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
                                                                id: rptRecipes
                                                                
                                                                Rectangle {
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 20
                                                                    Layout.alignment: Qt.AlignTop
                                                                    color: "#efefef"
                                                                    
                                                                    RowLayout{
                                                                        anchors.fill: parent
                                                                        spacing: 0

                                                                        LinearGradient {
                                                                            Layout.preferredWidth: parent.width - 100
                                                                            Layout.fillHeight: true
                                                                            start: Qt.point(0, 0)
                                                                            end: Qt.point(width, 0)
                                                                            gradient: Gradient {
                                                                                GradientStop { position: 0.0; color: 
                                                                                    ((modelData.id > 0 && modelData.id == recipeModel.id) 
                                                                                        || modelData.recipeCode == recipeModel.recipeCode) ? "#7eb038" : "#326195" }
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
                                                                                minimumPointSize: 5
                                                                                font.pointSize: 10
                                                                                fontSizeMode: Text.Fit
                                                                                font.bold: true
                                                                                text: (modelData.recipeCode ?? '')
                                                                            }
                                                                        }

                                                                        Rectangle{
                                                                            Layout.preferredWidth: 100
                                                                            Layout.fillHeight: true
                                                                            color: "transparent"

                                                                            Button{
                                                                                onClicked: showRecipe(modelData.id, modelData.recipeCode)
                                                                                width: 30
                                                                                height: parent.height
                                                                                anchors.top: parent.top
                                                                                anchors.topMargin: 0
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
                                                                                    anchors.topMargin: 2
                                                                                    anchors.leftMargin: 8
                                                                                    sourceSize.width: 30
                                                                                    sourceSize.height: 15
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

                                        // RECIPE FORM
                                        Rectangle{
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.margins: 5
                                            border.width: 1
                                            border.color: "#afafaf"
                                            radius: 5
                                            color: "#efefef"

                                            ColumnLayout{
                                                anchors.fill: parent
                                                anchors.leftMargin: 5
                                                anchors.rightMargin: 5
                                                anchors.topMargin: 10
                                                spacing: 0

                                                // RECIPE CODE FIELD
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Reçete No'
                                                            minimumPointSize: 5
                                                            font.pointSize: 14
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        TextField {
                                                            id: txtRecipeCode
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle {
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }
                                                        }
                                                    }
                                                }

                                                // RECIPE CAMERA RESULT BYTE INDEX
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Kamera Output Byte Formatı'
                                                            minimumPointSize: 5
                                                            font.pointSize: 9
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        TextField {
                                                            id: txtRecipeCamResultByteIndex
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle {
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }
                                                        }
                                                    }
                                                }

                                                // RECIPE START DELAY
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Başlama Gecikmesi(ms)'
                                                            minimumPointSize: 5
                                                            font.pointSize: 9
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        TextField {
                                                            id: txtRecipeStartDelay
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle {
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }
                                                        }
                                                    }
                                                }

                                                // RECIPE ROBOT READY PRM
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    RowLayout{
                                                        anchors.fill: parent

                                                        // RB TO RECIPE STARTED FIELD
                                                        Rectangle{
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            Layout.alignment: Qt.AlignTop
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 12
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'Reçete Seçildi (OUT)'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 9
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtRecipeRbToRecipeStarted
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
                                                                    background: Rectangle {
                                                                        radius: 5
                                                                        border.color: parent.focus ? "#326195" : "#888"
                                                                        border.width: 1
                                                                        color: parent.focus ? "#efefef" : "#ffffff"
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // RB FROM READY TO START FIELD
                                                        Rectangle{
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            Layout.alignment: Qt.AlignTop
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 12
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'Robot Hazır (IN)'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 9
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtRecipeRbFromReadyToStart
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
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

                                                // RECIPE ROBOT SCAN PRM
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    RowLayout{
                                                        anchors.fill: parent

                                                        // ROBOT TO START SCAN
                                                        Rectangle{
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            Layout.alignment: Qt.AlignTop
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 12
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'Tarama Başla (OUT)'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 9
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtRecipeRbToStartScan
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
                                                                    background: Rectangle {
                                                                        radius: 5
                                                                        border.color: parent.focus ? "#326195" : "#888"
                                                                        border.width: 1
                                                                        color: parent.focus ? "#efefef" : "#ffffff"
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // ROBOT FROM SCAN FINISHED
                                                        Rectangle{
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            Layout.alignment: Qt.AlignTop
                                                            color: "transparent"

                                                            ColumnLayout{
                                                                anchors.fill: parent

                                                                Label{
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 12
                                                                    Layout.alignment: Qt.AlignTop
                                                                    horizontalAlignment: Text.AlignLeft
                                                                    text:'Tarama Bitti (IN)'
                                                                    minimumPointSize: 5
                                                                    font.pointSize: 9
                                                                    fontSizeMode: Text.Fit
                                                                }

                                                                TextField {
                                                                    id: txtRecipeRbFromScanningFinished
                                                                    Layout.fillHeight: true
                                                                    Layout.fillWidth: true
                                                                    font.pixelSize: 9
                                                                    padding: 2
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

                                                // RECIPE IMAGE PATH FIELD
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Resim Dizini'
                                                            minimumPointSize: 5
                                                            font.pointSize: 9
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        TextField {
                                                            id: txtRecipeImagePath
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle {
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }

                                                            MouseArea{
                                                                anchors.fill: parent
                                                                onClicked: function(){
                                                                    showFileDialog();
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                // ACTION BUTTONS
                                                Rectangle{
                                                    Layout.preferredHeight: 30
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 2
                                                    color: "transparent"

                                                    RowLayout{
                                                        anchors.fill: parent
                                                        spacing: 10

                                                        // SECTION SAVE BUTTON
                                                        Button{
                                                            onClicked: function(){
                                                                saveRecipe();
                                                            }
                                                            Layout.fillWidth: true
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
                                                                sourceSize.width: 40
                                                                sourceSize.height: 20
                                                                fillMode: Image.Stretch
                                                                source: "../assets/save.png"
                                                            }
                                                        }

                                                        // SECTION DELETE BUTTON
                                                        Button{
                                                            onClicked: function(){
                                                                deleteRecipe();
                                                            }
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            padding: 5
                                                            background: Rectangle {
                                                                color: "#e6210b"
                                                                border.width: 1
                                                                border.color: "#333"
                                                                radius: 4
                                                            }
                                                            Image {
                                                                anchors.centerIn: parent
                                                                sourceSize.width: 40
                                                                sourceSize.height: 20
                                                                fillMode: Image.Stretch
                                                                source: "../assets/delete.png"
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

                            // TEST STEPS TAB CONTENT
                            Item{
                                id: stepsTab
                                visible: tabContent.currentItem == stepsTab

                                 Rectangle{ 
                                    anchors.fill: parent
                                    color:"transparent"

                                    RowLayout{
                                        anchors.fill: parent
                                        spacing: 0

                                        // STEPS LIST
                                        Rectangle{
                                            Layout.preferredWidth: parent.width * 0.7
                                            Layout.fillHeight: true
                                            color: "transparent"

                                            ColumnLayout{
                                                anchors.fill: parent

                                                // FILTER & BUTTONS
                                                Rectangle{
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    Layout.alignment: Qt.AlignTop
                                                    color: "transparent"

                                                    RowLayout{
                                                        anchors.fill: parent

                                                        Button{
                                                            text: "Yeni Adım"
                                                            onClicked: function(){
                                                                newStep();
                                                            }
                                                            Layout.alignment: Qt.AlignRight
                                                            id:btnNewStep
                                                            font.pixelSize: 16
                                                            font.bold: true
                                                            padding: 5
                                                            leftPadding: 30
                                                            palette.buttonText: "#333"
                                                            background: Rectangle {
                                                                border.width: btnNewStep.activeFocus ? 2 : 1
                                                                border.color: "#326195"
                                                                radius: 4
                                                                gradient: Gradient {
                                                                    GradientStop { position: 0 ; color: btnNewStep.pressed ? "#326195" : "#dedede" }
                                                                    GradientStop { position: 1 ; color: btnNewStep.pressed ? "#dedede" : "#326195" }
                                                                }
                                                            }

                                                            Image {
                                                                anchors.top: btnNewStep.top
                                                                anchors.left: btnNewStep.left
                                                                anchors.topMargin: 5
                                                                anchors.leftMargin: 5
                                                                sourceSize.width: 40
                                                                sourceSize.height: 20
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
                                                            Layout.preferredWidth: parent.width * 0.2
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
                                                                minimumPointSize: 5
                                                                font.pointSize: 14
                                                                fontSizeMode: Text.Fit
                                                                font.underline: true
                                                                font.bold: true
                                                                text: "Sıra No"
                                                            }
                                                        }

                                                        Rectangle{
                                                            Layout.preferredWidth: parent.width * 0.4
                                                            Layout.fillHeight: true
                                                            color: "transparent"

                                                            Text {
                                                                width: parent.width
                                                                height: parent.height
                                                                horizontalAlignment: Text.AlignHCenter
                                                                verticalAlignment: Text.AlignVCenter
                                                                color:"#333"
                                                                padding: 2
                                                                minimumPointSize: 5
                                                                font.pointSize: 14
                                                                fontSizeMode: Text.Fit
                                                                font.underline: true
                                                                font.bold: true
                                                                text: "Test Adı"
                                                            }
                                                        }

                                                        Rectangle{
                                                            Layout.preferredWidth: parent.width * 0.4 - 100
                                                            Layout.fillHeight: true
                                                            color: "transparent"

                                                            Text {
                                                                width: parent.width
                                                                height: parent.height
                                                                horizontalAlignment: Text.AlignHCenter
                                                                verticalAlignment: Text.AlignVCenter
                                                                color:"#333"
                                                                padding: 2
                                                                minimumPointSize: 5
                                                                font.pointSize: 14
                                                                fontSizeMode: Text.Fit
                                                                font.underline: true
                                                                font.bold: true
                                                                text: "Bölge"
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
                                                                minimumPointSize: 5
                                                                font.pointSize: 14
                                                                fontSizeMode: Text.Fit
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
                                                                id: rptSteps
                                                                
                                                                Rectangle {
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredHeight: 20
                                                                    Layout.alignment: Qt.AlignTop
                                                                    color: "#efefef"
                                                                    
                                                                    RowLayout{
                                                                        anchors.fill: parent
                                                                        spacing: 0

                                                                        LinearGradient {
                                                                            Layout.preferredWidth: parent.width * 0.2
                                                                            Layout.fillHeight: true
                                                                            start: Qt.point(0, 0)
                                                                            end: Qt.point(width, 0)
                                                                            gradient: Gradient {
                                                                                GradientStop { position: 0.0; color: 
                                                                                    ((modelData.id > 0 && modelData.id == stepModel.id) 
                                                                                        || modelData.testName == stepModel.testName) ? "#7eb038" : "#326195" }
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
                                                                                minimumPointSize: 5
                                                                                font.pointSize: 10
                                                                                fontSizeMode: Text.Fit
                                                                                font.bold: true
                                                                                text: (modelData.orderNo ?? 0)
                                                                            }
                                                                        }

                                                                        Rectangle{
                                                                            Layout.preferredWidth: parent.width * 0.4
                                                                            Layout.fillHeight: true
                                                                            color: "transparent"

                                                                            Text {
                                                                                width: parent.width
                                                                                height: parent.height
                                                                                horizontalAlignment: Text.AlignHCenter
                                                                                verticalAlignment: Text.AlignVCenter
                                                                                color:"#333"
                                                                                padding: 2
                                                                                minimumPointSize: 5
                                                                                font.pointSize: 10
                                                                                fontSizeMode: Text.Fit
                                                                                text: (modelData.testName ?? '')
                                                                            }
                                                                        }

                                                                        Rectangle{
                                                                            Layout.preferredWidth: parent.width * 0.4 - 100
                                                                            Layout.fillHeight: true
                                                                            color: "transparent"

                                                                            Text {
                                                                                width: parent.width
                                                                                height: parent.height
                                                                                horizontalAlignment: Text.AlignHCenter
                                                                                verticalAlignment: Text.AlignVCenter
                                                                                color:"#333"
                                                                                padding: 2
                                                                                minimumPointSize: 5
                                                                                font.pointSize: 10
                                                                                fontSizeMode: Text.Fit
                                                                                text: (modelData.sectionName ?? '')
                                                                            }
                                                                        }

                                                                        Rectangle{
                                                                            Layout.preferredWidth: 100
                                                                            Layout.fillHeight: true
                                                                            color: "transparent"

                                                                            Button{
                                                                                onClicked: showStep(modelData.id, modelData.testName)
                                                                                width: 30
                                                                                height: parent.height
                                                                                anchors.top: parent.top
                                                                                anchors.topMargin: 0
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
                                                                                    anchors.topMargin: 2
                                                                                    anchors.leftMargin: 8
                                                                                    sourceSize.width: 30
                                                                                    sourceSize.height: 15
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

                                        // STEP FORM
                                        Rectangle{
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.margins: 5
                                            border.width: 1
                                            border.color: "#afafaf"
                                            radius: 5
                                            color: "#efefef"

                                            ColumnLayout{
                                                anchors.fill: parent
                                                anchors.leftMargin: 5
                                                anchors.rightMargin: 5
                                                anchors.topMargin: 10
                                                spacing: 0

                                                // TEST NAME FIELD
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Test Adı'
                                                            minimumPointSize: 5
                                                            font.pointSize: 14
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        TextField {
                                                            id: txtStepTestName
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle {
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }
                                                        }
                                                    }
                                                }

                                                // TEST ORDER NO FIELD
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Sıra No'
                                                            minimumPointSize: 5
                                                            font.pointSize: 14
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        TextField {
                                                            id: txtStepOrderNo
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle {
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }
                                                        }
                                                    }
                                                }

                                                // TEST SECTION FIELD
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Bölge'
                                                            minimumPointSize: 5
                                                            font.pointSize: 14
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        ComboBox{
                                                            id: cmbStepSection
                                                            currentIndex: -1
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle{
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }

                                                            textRole: 'text'
                                                            valueRole: 'value'
                                                            model: []
                                                        }
                                                    }
                                                }

                                                // TEST RECIPE FIELD
                                                Rectangle{
                                                    Layout.preferredHeight: 40
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 0
                                                    color: "transparent"

                                                    ColumnLayout{
                                                        anchors.fill: parent

                                                        Label{
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 12
                                                            Layout.alignment: Qt.AlignTop
                                                            horizontalAlignment: Text.AlignLeft
                                                            text:'Reçete'
                                                            minimumPointSize: 5
                                                            font.pointSize: 14
                                                            fontSizeMode: Text.Fit
                                                        }

                                                        ComboBox{
                                                            id: cmbStepRecipe
                                                            currentIndex: -1
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            font.pixelSize: 9
                                                            padding: 2
                                                            background: Rectangle{
                                                                radius: 5
                                                                border.color: parent.focus ? "#326195" : "#888"
                                                                border.width: 1
                                                                color: parent.focus ? "#efefef" : "#ffffff"
                                                            }

                                                            textRole: 'text'
                                                            valueRole: 'value'
                                                            model: []
                                                        }
                                                    }
                                                }
                                                
                                                // ACTION BUTTONS
                                                Rectangle{
                                                    Layout.preferredHeight: 30
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    Layout.margins: 2
                                                    color: "transparent"

                                                    RowLayout{
                                                        anchors.fill: parent
                                                        spacing: 10

                                                        // SECTION SAVE BUTTON
                                                        Button{
                                                            onClicked: function(){
                                                                saveStep();
                                                            }
                                                            Layout.fillWidth: true
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
                                                                sourceSize.width: 40
                                                                sourceSize.height: 20
                                                                fillMode: Image.Stretch
                                                                source: "../assets/save.png"
                                                            }
                                                        }

                                                        // SECTION DELETE BUTTON
                                                        Button{
                                                            onClicked: function(){
                                                                deleteStep();
                                                            }
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            padding: 5
                                                            background: Rectangle {
                                                                color: "#e6210b"
                                                                border.width: 1
                                                                border.color: "#333"
                                                                radius: 4
                                                            }
                                                            Image {
                                                                anchors.centerIn: parent
                                                                sourceSize.width: 40
                                                                sourceSize.height: 20
                                                                fillMode: Image.Stretch
                                                                source: "../assets/delete.png"
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
                    }
                }
            }
        }
    }
}

