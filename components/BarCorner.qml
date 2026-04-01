import QtQuick

Item {
id: root

property string position: "top-left"


property color shapeColor: palette.window
property real cornerRadius: 30

width: cornerRadius
implicitHeight: cornerRadius

Canvas {
    id: cornerCanvas
    anchors.fill: parent

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = root.shapeColor; 
        ctx.beginPath();

        

        if (root.position === "top-left") {
            
            ctx.moveTo(width, 0); 
            ctx.lineTo(0, 0);     
            ctx.lineTo(0, height);    
            
            
            ctx.quadraticCurveTo(0, 0, width, 0);
        } else if (root.position === "top-right") {
            
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(width, height);
            
            ctx.quadraticCurveTo(width, 0, 0, 0);
        } else if (root.position === "bottom-left") {
            ctx.moveTo(0, 0);
            ctx.lineTo(0, height);
            ctx.lineTo(width, height);
            
            ctx.quadraticCurveTo(0, height, 0, 0);
        } else if (root.position === "bottom-right") {
            ctx.moveTo(width, 0);
            ctx.lineTo(width, height);
            ctx.lineTo(0, height);
            
            ctx.quadraticCurveTo(width, height, width, 0);
        }

        ctx.closePath(); 
        ctx.fill();      
    }

    
    Component.onCompleted: requestPaint()
    
    
    
    
}
onShapeColorChanged: cornerCanvas.requestPaint()

}