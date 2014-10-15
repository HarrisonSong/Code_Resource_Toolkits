function partition(v, left, right, pivotIndex){
    var pivotValue = v[pivotIndex];
    swap(v, pivotIndex, right);
    var storeIndex = left;
    for(var i = left; i < right; i++ ){
        if(v[i] < pivotValue){
            swap(v, storeIndex, i);
            storeIndex++;
        }
        console.log(v);
    }
    swap(v, right, storeIndex);
    return storeIndex;
}
         
function swap(v, indexA, indexB){
    var temp1 = v[indexA];
    var temp2 = v[indexB];
    v[indexA] = temp2;
    v[indexB] = temp1;
}         
         
function select(v, left, right, n){
    if(left == right){
        return v[left];
    }
    var pivotIndex = left;
    pivotIndex = partition(v, left, right, pivotIndex);
    if(n == pivotIndex){
        return v[n];
    }else if(n < pivotIndex){
        return select(v, left,pivotIndex - 1, n);
    }else{        
        return select(v, pivotIndex + 1, right, n);
    }
}

function sort(v, left, right){
    console.log("left " + left + " right " + right);
    if(left >= right){
        return;
    }
    var pivotIndex = left;
    console.log(pivotIndex);
    pivotIndex = partition(v, left, right, pivotIndex);
    console.log(v);
    if(pivotIndex > left){
        sort(v, left, pivotIndex - 1);    
    }
    if(pivotIndex < right){
        sort(v, pivotIndex + 1, right);
    }
}

function selection(v, k){
    sort(v, 0, v.length - 1);
    console.log(v.slice(0, k));
}
