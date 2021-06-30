var doc_item = document.getElementById("doc-item");
var index_item = document.getElementById("index-item");
var modifications_item = document.getElementById("modifications-item");
var related_item = document.getElementById("related-item");
var share_item = document.getElementById("share-item");
var more_item = document.getElementById("more-item");
var dropdown_modifications_item = document.getElementById("dropdown-modifications-item");
var dropdown_index_item = document.getElementById("dropdown-index-item");


doc_item.addEventListener("click", function () {
    doc_item.classList.add('active');
    index_item.classList.remove('active');
    modifications_item.classList.remove('active');
    related_item.classList.remove('active');
    share_item.classList.remove('active');
    // more_item.classList.remove('active');
    dropdown_index_item.classList.remove('active');
    dropdown_modifications_item.classList.remove('active');
})

index_item.addEventListener("click", function () {
    index_item.classList.add('active');
    doc_item.classList.remove('active');
    modifications_item.classList.remove('active');
    related_item.classList.remove('active');
    share_item.classList.remove('active');
    // more_item.classList.remove('active');
    dropdown_index_item.classList.remove('active');
    dropdown_modifications_item.classList.remove('active');
})

modifications_item.addEventListener("click", function () {
    modifications_item.classList.add('active');
    doc_item.classList.remove('active');
    index_item.classList.remove('active');
    related_item.classList.remove('active');
    share_item.classList.remove('active');
    // more_item.classList.remove('active');
    dropdown_index_item.classList.remove('active');
    dropdown_modifications_item.classList.remove('active');
})

related_item.addEventListener("click", function () {
    related_item.classList.add('active');
    doc_item.classList.remove('active');
    index_item.classList.remove('active');
    modifications_item.classList.remove('active');
    share_item.classList.remove('active');
    // more_item.classList.remove('active');
    dropdown_index_item.classList.remove('active');
    dropdown_modifications_item.classList.remove('active');
})

share_item.addEventListener("click", function () {
    share_item.classList.add('active')
    related_item.classList.remove('active');
    doc_item.classList.remove('active');
    index_item.classList.remove('active');
    modifications_item.classList.remove('active');
    // more_item.classList.remove('active');
    dropdown_index_item.classList.remove('active');
    dropdown_modifications_item.classList.remove('active');
})

more_item.addEventListener("click", function () {
    // more_item.classList.add('active');
    related_item.classList.remove('active');
    doc_item.classList.remove('active');
    index_item.classList.remove('active');
    modifications_item.classList.remove('active');
    share_item.classList.remove('active');
    dropdown_index_item.classList.remove('active');
    dropdown_modifications_item.classList.remove('active');
})

dropdown_index_item.addEventListener("click", function() {
    more_item.classList.remove('active');
    dropdown_modifications_item.classList.remove('active');
})

dropdown_modifications_item.addEventListener("click", function() {
    more_item.classList.remove('active');
    dropdown_index_item.classList.remove('active');
})

//Copy to clipboard
var $temp = $("<input>");
var $url = $(location).attr('href');

$('.clipboard').on('click', function() {
    $("body").append($temp);
    $temp.val($url).select();
    document.execCommand("copy");
    $temp.remove();
    // $("p").text("URL copied!");
    document.getElementById("clipboard-alert").style.display = "block";
})

//close clipboard message
var clipboard_button = document.getElementById("clipboard-button");
clipboard_button.addEventListener('click', function(){
    document.getElementById("clipboard-alert").style.display = "none";
});
