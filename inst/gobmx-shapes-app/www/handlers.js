$( document ).ready(function() {

$(document).on('click', '.needed', function () {
  console.log(this.id)
  Shiny.onInputChange('last_click',this.id);
});

$(document).on('click', '.needed', function(){
    $('.needed').removeClass('basic_active');
    $(this).addClass('basic_active');
});

$(document).on('click', '.apiClick', function () {
  Shiny.onInputChange('last_apiClick',this.id);
});

$(document).on('click', '.apiClick', function(){
    $('.apiClick').removeClass('api_active');
    $(this).addClass('api_active');
});
  
  
let myDocument = document.documentElement;
let btn = document.getElementById("fs");
//btn.innerHTML = '<img src="www/img/full.png"/>';
btn.addEventListener("click", ()=>{
    if(btn.textContent == "Fullscreen"){
        if (myDocument.requestFullscreen) {
            myDocument.requestFullscreen();
        } 
        else if (myDocument.msRequestFullscreen) {
            myDocument.msRequestFullscreen();
        } 
        else if (myDocument.mozRequestFullScreen) {
            myDocument.mozRequestFullScreen();
        }
        else if(myDocument.webkitRequestFullscreen) {
            myDocument.webkitRequestFullscreen();
        }
        btn.textContent = "Exit Fullscreen";
    }
    else{
        if(document.exitFullscreen) {
            document.exitFullscreen();
        }
        else if(document.msexitFullscreen) {
            document.msexitFullscreen();
        }
        else if(document.mozexitFullscreen) {
            document.mozexitFullscreen();
        }
        else if(document.webkitexitFullscreen) {
            document.webkitexitFullscreen();
        }
        btn.textContent = "Fullscreen";
    }
});


function show(){
  document.getElementById('trB').style.display='table-row';
}

function hide(){
  document.getElementById('trB').style.display='none';
}

});

