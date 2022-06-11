import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.14
import QtQuick.Layouts 1.2
import QtQuick.Dialogs 1.1
import QtGraphicalEffects 1.0

Popup {
    id: popupContainer
    
    property int stepId: 0
    property int recordId: 0
    property var modelObject: new Object({ variables: [] })
    property var variableModel: new Object({ id:0 })
    property string lastCode: ""

    modal: true
    dim: true
    Overlay.modal: Rectangle {
        color: "#aacfdbe7"
    }

    anchors.centerIn: parent
    width: parent.width * 0.7
    height: parent.height * 0.7

    enter: Transition {
        NumberAnimation { properties: "opacity"; from: 0; to: 1 }
    }

    exit: Transition {
        NumberAnimation { properties: "opacity"; from: 1; to: 0 }
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

    Component.onCompleted: function(){
        bindModel();
    }

    function bindModel(){
        if (stepId > 0){
            backend.requestStepVariables(stepId);
        }
    }

    function showVariable(id, variableName){
        recordId = id;
        variableModel = modelObject.variables.find(d => d.id == recordId || d.variableName == variableName);
        if (variableModel && variableModel != null){
            txtVariableName.text = variableModel.variableName;
            txtVariableValue.text = (variableModel.variableValue ?? 0).toString();
            txtDescription.text = variableModel.description;
        }
    }

    function newVariable(){
        variableModel = { id:0 };
        txtVariableName.text = '';
        txtVariableValue.text = '';
        txtDescription.text = '';
        txtDescription.focus = true;
    }

    function saveModel(){
        if (variableModel){
            waitingIcon.visible = true;

            variableModel.variableName = txtVariableName.text;
            variableModel.variableValue = txtVariableValue.text;
            variableModel.description = txtDescription.text;

            if (!modelObject.variables.includes(variableModel))
                modelObject.variables.push(variableModel);

            lastCode = variableModel.variableName;

            let processFlag = false;
            delay(200, function(){
                if (processFlag == false){
                    backend.saveStepVariables(stepId, JSON.stringify(modelObject.variables));
                    processFlag = true;
                }
            });
        }
    }

    function deleteModel(variableId){
        waitingIcon.visible = true;

        let processFlag = false;
        delay(200, function(){
            if (processFlag == false){
                backend.deleteVariable(variableId);
                processFlag = true;
            }
        });
    }

    function incValue(){
        try {
            let currentValue = txtVariableValue.text.length > 0 ? parseInt(txtVariableValue.text) : 0;
            currentValue++;
            txtVariableValue.text = currentValue.toString();
        } catch (error) {
            
        }
    }

    function decValue(){
        try {
            let currentValue = txtVariableValue.text.length > 0 ? parseInt(txtVariableValue.text) : 0;
            currentValue--;
            txtVariableValue.text = currentValue.toString();
        } catch (error) {
            
        }
    }

    // BACKEND SIGNALS & SLOTS
    Connections {
        target: backend

        function onGetStepVariables(variablesInfo){
            const data = JSON.parse(variablesInfo);
            if (data){
                modelObject.variables = data;
                rptVars.model = modelObject.variables;

                if (lastCode.length > 0)
                    showVariable(0, lastCode);

                lastCode = "";
            }
        }

        // all step variables
        function onSaveStepVariableFinished(saveResult){
            waitingIcon.visible = false;
            var resultData = JSON.parse(saveResult);
            if (resultData){
                if (resultData.Result){
                    bindModel();
                }
            }
        }

        // specific variable
        function onDeleteStepVariableFinished(saveResult){
            waitingIcon.visible = false;
            var resultData = JSON.parse(saveResult);
            if (resultData){
                if (resultData.Result){
                    bindModel();
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
        text: "Bu değişkeni silmek istediğinizden emin misiniz?"
        onYes: {
            visible = false;
            deleteModel(recordId);
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
                        text: "Değişken Tanımları"
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

                        // DELETE BUTTON
                        // Button{
                        //     onClicked: function(){
                        //         msgBoxConfirmDelete.visible = true;
                        //     }
                        //     Layout.preferredWidth: 49
                        //     Layout.fillHeight: true
                        //     Layout.alignment: Qt.AlignRight
                        //     padding: 5
                        //     background: Rectangle {
                        //         color: "#e6210b"
                        //         border.width: 1
                        //         border.color: "#333"
                        //         radius: 4
                        //     }
                        //     Image {
                        //         anchors.top: parent.top
                        //         anchors.left: parent.left
                        //         anchors.topMargin: 5
                        //         anchors.leftMargin: 10
                        //         sourceSize.width: 50
                        //         sourceSize.height: 30
                        //         fillMode: Image.Stretch
                        //         source: "../assets/delete.png"
                        //     }
                        // }

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

                // VARIABLE LIST
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
                                    text: "Yeni Değişken"
                                    onClicked: function(){
                                        newVariable();
                                    }
                                    Layout.alignment: Qt.AlignRight
                                    id:btnNewVariable
                                    font.pixelSize: 16
                                    font.bold: true
                                    padding: 5
                                    leftPadding: 30
                                    palette.buttonText: "#333"
                                    background: Rectangle {
                                        border.width: btnNewVariable.activeFocus ? 2 : 1
                                        border.color: "#326195"
                                        radius: 4
                                        gradient: Gradient {
                                            GradientStop { position: 0 ; color: btnNewVariable.pressed ? "#326195" : "#dedede" }
                                            GradientStop { position: 1 ; color: btnNewVariable.pressed ? "#dedede" : "#326195" }
                                        }
                                    }

                                    Image {
                                        anchors.top: btnNewVariable.top
                                        anchors.left: btnNewVariable.left
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
                                        text: "Açıklama"
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
                                        text: "Değişken"
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
                                        text: "Değer"
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
                                        id: rptVars
                                        
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
                                                            ((modelData.id > 0 && modelData.id == variableModel.id) 
                                                                || modelData.variableName == variableModel.variableName) ? "#7eb038" : "#326195" }
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
                                                        text: (modelData.description ?? '')
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
                                                        text: (modelData.variableName ?? '')
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
                                                        text: (modelData.variableValue ?? 0)
                                                    }
                                                }

                                                Rectangle{
                                                    Layout.preferredWidth: 100
                                                    Layout.fillHeight: true
                                                    color: "transparent"

                                                    Button{
                                                        onClicked: showVariable(modelData.id, modelData.variableName)
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

                // VARIABLE FORM
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

                        // DESCRIPTION FIELD
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
                                    text:'Açıklama'
                                    minimumPointSize: 5
                                    font.pointSize: 14
                                    fontSizeMode: Text.Fit
                                }

                                TextField {
                                    id: txtDescription
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

                        // VARIABLE NAME FIELD
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
                                    text:'Değişken'
                                    minimumPointSize: 5
                                    font.pointSize: 14
                                    fontSizeMode: Text.Fit
                                }

                                TextField {
                                    id: txtVariableName
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

                        // VARIABLE VALUE FIELD
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
                                    text:'Değer'
                                    minimumPointSize: 5
                                    font.pointSize: 14
                                    fontSizeMode: Text.Fit
                                }

                                Rectangle{
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    color: "transparent"

                                    RowLayout{
                                        anchors.fill: parent

                                        TextField {
                                            id: txtVariableValue
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

                                            // validator: IntValidator {bottom: -500; top: 500}
                                        }

                                        // INC & DEC BUTTONS
                                        Rectangle{
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 80
                                            color: "transparent"

                                            RowLayout{
                                                anchors.fill: parent
                                                spacing:0

                                                // INC BUTTON
                                                Button{
                                                    id: btnVarUp
                                                    text: ""
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    onClicked: incValue()
                                                    padding: 10
                                                    palette.buttonText: "#333"
                                                    background: Rectangle {
                                                        border.width: btnVarUp.activeFocus ? 2 : 1
                                                        border.color: "#333"
                                                        radius: 4
                                                        gradient: Gradient {
                                                            GradientStop { position: 0 ; color: btnVarUp.pressed ? "#AAA" : "#dedede" }
                                                            GradientStop { position: 1 ; color: btnVarUp.pressed ? "#dedede" : "#AAA" }
                                                        }
                                                    }

                                                    Image {
                                                        anchors.centerIn: parent
                                                        sourceSize.width: parent.width - 5
                                                        sourceSize.height: parent.height - 5
                                                        fillMode: Image.Stretch
                                                        source: "../assets/increase.png"
                                                    }
                                                }

                                                // DEC BUTTON
                                                Button{
                                                    id: btnVarDec
                                                    text: ""
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    onClicked: decValue()
                                                    padding: 10
                                                    palette.buttonText: "#333"
                                                    background: Rectangle {
                                                        border.width: btnVarDec.activeFocus ? 2 : 1
                                                        border.color: "#333"
                                                        radius: 4
                                                        gradient: Gradient {
                                                            GradientStop { position: 0 ; color: btnVarDec.pressed ? "#AAA" : "#dedede" }
                                                            GradientStop { position: 1 ; color: btnVarDec.pressed ? "#dedede" : "#AAA" }
                                                        }
                                                    }

                                                    Image {
                                                        anchors.centerIn: parent
                                                        sourceSize.width: parent.width - 5
                                                        sourceSize.height: parent.height - 5
                                                        fillMode: Image.Stretch
                                                        source: "../assets/decrease.png"
                                                    }
                                                }
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
                            Layout.topMargin: 10
                            color: "transparent"

                            RowLayout{
                                anchors.fill: parent
                                spacing: 10

                                // SECTION SAVE BUTTON
                                Button{
                                    onClicked: function(){
                                        saveModel();
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
                                    visible: variableModel.id > 0
                                    onClicked: function(){
                                        deleteModel(variableModel.id);
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

