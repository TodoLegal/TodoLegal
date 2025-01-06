console.log("clear_searchInput.js is loaded");
var input_fields = document.getElementsByClassName("search-input");
var clear_buttons = document.getElementsByClassName("clear--text");

for (let i = 0; i < input_fields.length; i++){
    input_fields[i].addEventListener('input', function(){
        for(let j=0; j<clear_buttons.length; j++)
        {
            if(input_fields[i].value != ""){
                clear_buttons[j].style.display = "block";
            }else{
                clear_buttons[j].style.display = "none";
            }
        }
    });

}

for (let i = 0; i < clear_buttons.length; i++) {
    clear_buttons[i].addEventListener('click', function (){
        for (let j = 0; j < input_fields.length; j++) {
            input_fields[j].value = "";
            clear_buttons[i].style.display = "none";
            }
    })   
}
