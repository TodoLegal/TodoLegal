var input_field = document.getElementById("searchInput");
var clear_button = document.getElementById("clearButton");

function clearText(wichButton) {
    input_field.value = "";
    clear_button.style.display = "none";
}

clear_button.addEventListener('click', (event) => {
    clearText();
});

input_field.addEventListener('input', (event) => {
    if(input_field.value != ""){
        clear_button.style.display = "block";
    }else{
        clear_button.style.display = "none";
    }
});
