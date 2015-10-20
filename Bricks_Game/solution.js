var list = [];
var table = {};

function processTable(n){
  var index = 0;
  while(index <= n){
    if(index <= 0) table[0] = 0;
    if(index === 1) table[1] = list[0];
    if(index === 2) table[2] = list[0] + list[1];
    if(index === 3) table[3] = list[0] + list[1] + list[2];
    if(index === 4) table[4] = list[1] + list[2] + list[3];
    if(index === 5) table[5] = list[4] + Math.max(list[2] + list[3], list[0]);
    if(index >= 6){
      table[index] = Math.max(list[index - 1] + Math.min(table[index - 2], table[index - 3], table[index - 4]),
          list[index - 1] + list[index - 2] + Math.min(table[index - 3], table[index - 4], table[index - 5]),
          list[index - 1] + list[index - 2] + list[index - 3] + Math.min(table[index - 4], table[index - 5], table[index - 6]));
    }
    index++;
  }
}

function processData(input) {
    var inputArray = input.split("\n");
    var outputArray = [];
    for(var i = 0; i < inputArray[0]; i++){
        table = {};
        list = inputArray[i * 2 + 2].split(" ").map(Number).reverse();
        var n = parseInt(inputArray[i * 2 + 1]);
        processTable(n);
        outputArray.push(table[n]);
    }
    outputArray.map(function(element){
      console.log(element);
    });
}

var fs = require('fs');

function readModuleFile(path, callback) {
    try {
        var filename = require.resolve(path);
        fs.readFile(filename, 'utf8', callback);
    } catch (e) {
        callback(e);
    }
}

readModuleFile('./test.txt', function (err, input) {
    processData(input);
});
