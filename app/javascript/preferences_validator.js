function validateCheckedPreferences (){
    const tags = document.getElementsByClassName("tags-checkbox");
    const frequency = document.getElementsByClassName("frequency-radiobtn");

    let isAnyTagSelected = false;
    let isAnyFrequencySelected = false;

    for (let index = 0; index < tags.length; index++) {
      if ( tags[index].checked ){
        isAnyTagSelected = true;
      }
    }

    for (let index = 0; index < frequency.length; index++) {
      if ( frequency[index].checked ){
        isAnyFrequencySelected = true;
      }
    }

    if ( isAnyTagSelected == false || isAnyFrequencySelected == false ){
      event.preventDefault();
      event.stopPropagation();
      $('#savePreferencesBtn').popover('show')
    }else{
      $('#savePreferencesBtn').unbind();
      $('#savePreferencesBtn').popover('hide')
    }
}