console.log("help_card.js is loaded");

var inputFields = document.getElementsByClassName('search-input');
var helpCards = document.getElementsByClassName('help-card');

// console.log(inputFields)
// console.log(helpCards)
let i = 0;

for(i=0; i<inputFields.length; i++)
{
  let j = 0;
  inputFields[i].addEventListener('focus', function(){
    for(j=0; j<helpCards.length; j++)
    {
      helpCards[j].style.display = 'block';
    }
  });

  inputFields[i].addEventListener('focusout', function(){
    for(j=0; j<helpCards.length; j++)
    {
      helpCards[j].style.display = 'none';
    }
  });

  inputFields[i].addEventListener('keypress', function (e) {
    for(j=0; j<helpCards.length; j++) {
      if (e.key === 'Enter') {
          helpCards[j].style.display = 'none';
      }
    }
  });
}
