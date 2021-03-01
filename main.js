/*
variables
*/
var model;
//var canvas = document.getElementById('canvas');
var canvas = canvas = window._canvas = new fabric.Canvas('canvas');
var ctx = canvas.getContext('2d');
var classNames = [];
var coords = [];
// var mousePressed = false;
var mode;

var radius = 5;
var controller = new Leap.Controller();


/*
prepare the drawing canvas 
*/
$(function() {
    // canvas = window._canvas = new fabric.Canvas('canvas');
    // canvas.backgroundColor = '#ffffff';
    // canvas.isDrawingMode = 0;
    // canvas.freeDrawingBrush.color = "black";
    // canvas.freeDrawingBrush.width = 10;
    // canvas.renderAll();
    // //setup listeners 
    // canvas.on('mouse:up', function(e) {
    //     getFrame();
    //     mousePressed = false
    // });
    // canvas.on('mouse:down', function(e) {
    //     mousePressed = true
    // });
    // canvas.on('mouse:move', function(e) {
    //     recordCoor(e)
    // });
    ctx.translate(canvas.width/2, canvas.height);
    ctx.fillStyle = "rgba(0,0,0,0.9)";
    ctx.strokeStyle = "rgba(0,0,0,0.9)"
    ctx.lineWidth = 5;  

    function drawCircle(center, radius, color, fill) {
        // Make an closed arc with a complete rotation
        ctx.beginPath();
        ctx.arc(center[0], center[1], radius, 0, 2*Math.PI);
        ctx.closePath();
        ctx.lineWidth = 4;
        // Choose whether to fill or outline the circle
        if (fill) {
          ctx.fillStyle = color;
          ctx.fill();
        } else {
          ctx.strokeStyle = color;
          ctx.stroke();
        }
      }
      

    function draw(frame) {
        //console.log("drawing")
        // set up data array and other variables
        var data = [],
            pos, i, len;
    
        //drawCircle([canvas.width/2, 50], 20, '#0F0');
            // cover the canvas with a 10% opaque layer for fade out effect.
        //ctx.fillStyle = "rgba(0,0,0,0.9)";
        ctx.fillStyle = "rgba(255,255,255,0.01)";
        ctx.fillRect(-canvas.width/2,-canvas.height,canvas.width,canvas.height);
    
        // set the fill to black for the points
        ctx.fillStyle = "rgba(0,0,0,1)";
    
        // loop over the frame's pointables
       
        for (i=0, len=frame.pointables.length; i<len; i++) {
          // get the pointable and its position
          pos = frame.pointables[i].tipPosition;
           
          

          //ctx.fillRect(-canvas.width/2,-canvas.height,canvas.width,canvas.height);
    
          // add the position data to our data array
          data.push(pos);
        //   if (pos.x >= 0 && pos.y >= 0){
        //       coords.push(pos)
        // }
        var position = [pos[0],pos[1]];
        //console.log(position); 
        coords.push(position);
    
 
        // draw the circle where the pointable is
          ctx.beginPath();
          ctx.arc(pos[0]-radius/2 ,-(pos[1]-radius/2),radius,0,2*Math.PI);
          ctx.fill();
          ctx.stroke();
          
        }
        getFrame();
    }

    Leap.loop(draw);
    // canvas.on('mouse:out', function(e) {
    //         console.log("frame update");
            
    // });
})

/*
set the table of the predictions 
*/
function setTable(top5, probs) {
    //loop over the predictions 
    for (var i = 0; i < top5.length; i++) {
        let sym = document.getElementById('sym' + (i + 1))
        let prob = document.getElementById('prob' + (i + 1))
        sym.innerHTML = top5[i]
        prob.innerHTML = Math.round(probs[i] * 100)
    }
    //create the pie 
    createPie(".pieID.legend", ".pieID.pie");
}

/*
record the current drawing coordinates
*/
// function recordCoor(event) {
//     var pointer = canvas.getPointer(event.e);
//     var posX = pointer.x;
//     var posY = pointer.y;

//     if (posX >= 0 && posY >= 0 && mousePressed) {
//         coords.push(pointer)
//     }
// }

/*
get the best bounding box by trimming around the drawing
*/
function getMinBox() {
    //get coordinates 
    var coorX = coords.map(function(p) {
        return p.x
    });
    var coorY = coords.map(function(p) {
        return p.y
    });

    //find top left and bottom right corners 
    var min_coords = {
        x: Math.min.apply(null, coorX),
        y: Math.min.apply(null, coorY)
    }
    var max_coords = {
        x: Math.max.apply(null, coorX),
        y: Math.max.apply(null, coorY)
    }

    //return as strucut 
    return {
        min: min_coords,
        max: max_coords
    }
}

/*
get the current image data 
*/
function getImageData() {
        //get the minimum bounding box around the drawing 
        const mbb = getMinBox()

        //get image data according to dpi 
        const dpi = window.devicePixelRatio
        const imgData = canvas.contextContainer.getImageData(mbb.min.x * dpi, mbb.min.y * dpi,
                                                      (mbb.max.x - mbb.min.x) * dpi, (mbb.max.y - mbb.min.y) * dpi);
        return imgData
    }

/*
get the prediction 
*/
function getFrame() {
    //make sure we have at least two recorded coordinates 
    console.log("frame");
    if (coords.length >= 2) {

        //get the image data from the canvas 
        const imgData = getImageData()

        //get the prediction 
        const pred = model.predict(preprocess(imgData)).dataSync()

        //find the top 5 predictions 
        const indices = findIndicesOfMax(pred, 5)
        const probs = findTopValues(pred, 5)
        const names = getClassNames(indices)

        //set the table 
        setTable(names, probs)
    }

}

/*
get the the class names 
*/
function getClassNames(indices) {
    var outp = []
    for (var i = 0; i < indices.length; i++)
        outp[i] = classNames[indices[i]]
    return outp
}

/*
load the class names 
*/
async function loadDict() {
    if (mode == 'ar')
        loc = 'model/class_names_ar.txt'
    else
        loc = 'model/class_names.txt'
    
    await $.ajax({
        url: loc,
        dataType: 'text',
    }).done(success);
}

/*
load the class names
*/
function success(data) {
    const lst = data.split(/\n/)
    for (var i = 0; i < lst.length - 1; i++) {
        let symbol = lst[i]
        classNames[i] = symbol
    }
}

/*
get indices of the top probs
*/
function findIndicesOfMax(inp, count) {
    var outp = [];
    for (var i = 0; i < inp.length; i++) {
        outp.push(i); // add index to output array
        if (outp.length > count) {
            outp.sort(function(a, b) {
                return inp[b] - inp[a];
            }); // descending sort the output array
            outp.pop(); // remove the last index (index of smallest element in output array)
        }
    }
    return outp;
}

/*
find the top 5 predictions
*/
function findTopValues(inp, count) {
    var outp = [];
    let indices = findIndicesOfMax(inp, count)
    // show 5 greatest scores
    for (var i = 0; i < indices.length; i++)
        outp[i] = inp[indices[i]]
    return outp
}

/*
preprocess the data
*/
function preprocess(imgData) {
    return tf.tidy(() => {
        //convert to a tensor 
        let tensor = tf.browser.fromPixels(imgData, numChannels = 1)
        
        //resize 
        const resized = tf.image.resizeBilinear(tensor, [28, 28]).toFloat()
        
        //normalize 
        const offset = tf.scalar(255.0);
        const normalized = tf.scalar(1.0).sub(resized.div(offset));

        //We add a dimension to get a batch shape 
        const batched = normalized.expandDims(0)
        return batched
    })
}

/*
load the model
*/
async function start(cur_mode) {
    //arabic or english
    mode = cur_mode
    
    //load the model 
    model = await tf.loadLayersModel('model/model.json')
    
    //warm up 
    model.predict(tf.zeros([1, 28, 28, 1]))
    
    //allow drawing on the canvas 
    //allowDrawing()
    document.getElementById('status').innerHTML = 'Model Loaded';
    
    //load the class names
    await loadDict()
}

/*
allow drawing on canvas
*/
function allowDrawing() {
    canvas.isDrawingMode = 1;
    if (mode == 'en')
        document.getElementById('status').innerHTML = 'Model Loaded';
    else
        document.getElementById('status').innerHTML = 'تم التحميل';
    $('button').prop('disabled', false);
    var slider = document.getElementById('myRange');
    slider.oninput = function() {
        canvas.freeDrawingBrush.width = this.value;
    };
}

/*
clear the canvs 
*/
function erase() {
    canvas.clear();
    canvas.backgroundColor = '#ffffff';
    coords = [];
}
