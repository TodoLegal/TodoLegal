function trimArticlesforPreview() {
    var link_elements = document.getElementsByClassName("articles-preview");
    var left = "";
    var right = ""
    var nodes;
    var resultText = "";
    for (i = 0 ; i < link_elements.length; i++){
      nodes = link_elements[i].childNodes;
      for( j = 0 ; j < nodes.length; j++){
        if(nodes[j].tagName == "H6") {
          resultText = "";
          break;
        }
        if(nodes.length == 1) {
          resultText = nodes[j].textContent;
          break;
        }
        if (nodes[j].nodeType == Node.ELEMENT_NODE){
          if (nodes[j].previousSibling.nodeType == Node.TEXT_NODE){
            left = nodes[j].previousSibling.textContent.slice(-67);
            temp = left.split(/^[^\s]*\s/);
            left = temp[1];
          }
          if(nodes[j].nextSibling.nodeType == Node.TEXT_NODE){
            right = nodes[j].nextSibling.textContent.slice(0, 65) + "... ";
          }
          resultText += left + nodes[j].outerHTML + right;
        }
      }
      if(resultText)
        link_elements[i].innerHTML = resultText;
      resultText = "";
    }
}

//modern way but not fully supported by all the browsers
// document.addEventListener("DOMContentLoaded", function(event){
//   hi();
// });

$(document).ready(function(){
    trimArticlesforPreview();
})