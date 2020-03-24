function colapseIndice() {
  $('#sidebar').removeClass('active');
  $('.overlay').removeClass('active');
}

/* Tabs navigation */
var active_tab = "#articulos"
window.onscroll = function() {onScrollCallback()};

var bigger_sections = document.getElementsByClassName("bigger-section");

function setStickySectionHeading(header_text)
{
  document.getElementById('sticky_nav_header').innerText = header_text
}

function onScrollCallback()
{
  if(active_tab == "#articulos")
  {
    var sticky_header = null
    for(var i=0; i<bigger_sections.length; i++)
    {
      if (bigger_sections[i].offsetTop != 0 && bigger_sections[i].offsetTop - 1 <= window.pageYOffset)
      {
        sticky_header = bigger_sections[i]
      }
    }
    if(sticky_header)
      setStickySectionHeading(sticky_header.innerText)
    else
      setStickySectionHeading("")
  }
}

$('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
  var target = $(e.target).attr('href')
  setStickySectionHeading("")
  active_tab = target
});

/* Indice filter */

function filterIndice() {
  var input, filter, list, i, txtValue;
  input = document.getElementById("query_input");
  filter = input.value.toUpperCase();
  list = document.getElementById("sidebar_index");
  li = list.getElementsByTagName("li");
  for (i = 0; i < li.length; i++) {
    txtValue = li[i].textContent || li[i].innerText;
    if (txtValue.toUpperCase().indexOf(filter) > -1) {
      li[i].style.display = "";
    } else {
      li[i].style.display = "none";
    }
  }
}

/* Search browser */

var currrent_highlighted = 0;
var highlighted_count = document.getElementsByClassName('highlighted').length;

if(highlighted_count > 0)
  updateHighlightedView()

function updateHighlightedView()
{
  document.getElementById("result-count-big").innerText = (currrent_highlighted + 1) +"/"+highlighted_count
  document.getElementById("result-count-small").innerText = (currrent_highlighted + 1) +"/"+highlighted_count
  element_highlighted = document.getElementsByClassName('highlighted')[currrent_highlighted]
  element_highlighted.scrollIntoView({block: 'center'})
  element_highlighted.style["color"]="var(--c-selected-highlight)"
  element_highlighted.style["background-color"]="var(--c-selected-highlight-background)"
}

function browseHighlightedUp()
{
  last_element_highlighted = document.getElementsByClassName('highlighted')[currrent_highlighted]
  if(last_element_highlighted)
  {
    last_element_highlighted.style["color"] = "var(--c-highlight)"
    last_element_highlighted.style["background-color"] = "var(--c-highlight-background)"
  }
  currrent_highlighted -= 1;
  if(currrent_highlighted < 0)
    currrent_highlighted = highlighted_count - 1;
  updateHighlightedView()
}

function browseHighlightedDown()
{
  last_element_highlighted = document.getElementsByClassName('highlighted')[currrent_highlighted]
  if(last_element_highlighted)
  {
    last_element_highlighted.style.color = "var(--c-highlight)"
    last_element_highlighted.style["background-color"] = "var(--c-highlight-background)"
  }
  currrent_highlighted += 1;
  if(currrent_highlighted >= highlighted_count)
    currrent_highlighted = 0;
  updateHighlightedView()
}

/* Article navigation */

var current_article = 0;
var article_focused = null;

var articles_element = document.getElementsByClassName('article')

function onClickArticle(clicked_article_id)
{
  if(article_focused)
  {
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
  }
  current_article = clicked_article_id
  article_focused = document.getElementById('article_count_' + current_article)
  article_focused.style['background-color'] = "var(--c-selected-article-background)"
  article_focused.style['color'] = "var(--c-selected-article-text)"
  return true;
}

function gotoArticle(article_number)
{
  if (bigger_section_focused)
  {
    current_article = parseInt(bigger_section_focused.getAttribute("last_article"))
    bigger_section_focused.style['background-color'] = "var(--c-original-background)"
    bigger_section_focused.style['color'] = "var(--c-original-text)"
    bigger_section_focused = null
  } else if(article_focused)
  {
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
  }

  current_article = article_number
  
  article_focused = document.getElementById('article_count_' + current_article)
  article_focused.scrollIntoView({block: 'center'})
  article_focused.style['background-color'] = "var(--c-selected-article-background)"
  article_focused.style['color'] = "var(--c-selected-article-text)"
}

function focusPreviousArticle()
{
  if (bigger_section_focused)
  {
    current_article = parseInt(bigger_section_focused.getAttribute("last_article"))
    bigger_section_focused.style['background-color'] = "var(--c-original-background)"
    bigger_section_focused.style['color'] = "var(--c-original-text)"
    bigger_section_focused = null
  } else if(article_focused)
  {
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
    current_article -= 1
  } else
  {
    current_article -= 1
  }
  
  article_focused = document.getElementById('article_count_' + current_article)
  article_focused.scrollIntoView({block: 'center'})
  article_focused.style['background-color'] = "var(--c-selected-article-background)"
  article_focused.style['color'] = "var(--c-selected-article-text)"
}

function focusNextArticle()
{
  if (bigger_section_focused)
  {
    current_article = parseInt(bigger_section_focused.getAttribute("next_article"))
    bigger_section_focused.style['background-color'] = "var(--c-original-background)"
    bigger_section_focused.style['color'] = "var(--c-original-text)"
    bigger_section_focused = null
  } else if(article_focused)
  {
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
    current_article += 1
  } else
  {
    current_article += 1
  }

  article_focused = document.getElementById('article_count_' + current_article)
  article_focused.scrollIntoView({block: 'center'})
  article_focused.style['background-color'] = "var(--c-selected-article-background)"
  article_focused.style['color'] = "var(--c-selected-article-text)"
}

/* Bigger section navigation */

var current_bigger_section = 0;
var bigger_section_focused = null;

function focusPreviousBiggerSection()
{
  if(article_focused)
  {
    current_bigger_section = parseInt(article_focused.getAttribute("last_bigger_section"))
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
    article_focused = null
  } else if(bigger_section_focused)
  {
    bigger_section_focused.style['background-color'] = "var(--c-original-background)"
    bigger_section_focused.style['color'] = "var(--c-original-text)"
    current_bigger_section -= 1
  }

  bigger_section_focused = document.getElementById('bigger_section_' + current_bigger_section)
  bigger_section_focused.scrollIntoView({block: 'center'})
  bigger_section_focused.style['background-color'] = "var(--c-selected-bigger-section-background)"
  bigger_section_focused.style['color'] = "var(--c-selected-bigger-section-text)"
}

function focusNextBiggerSection()
{
  if(article_focused)
  {
    current_bigger_section = parseInt(article_focused.getAttribute("next_bigger_section"))
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
    article_focused = null
  } else if(bigger_section_focused)
  {
    bigger_section_focused.style['background-color'] = "var(--c-original-background)"
    bigger_section_focused.style['color'] = "var(--c-original-text)"
    current_bigger_section += 1
  }
  
  bigger_section_focused = document.getElementById('bigger_section_' + current_bigger_section)
  bigger_section_focused.scrollIntoView({block: 'center'})
  bigger_section_focused.style['background-color'] = "var(--c-selected-bigger-section-background)"
  bigger_section_focused.style['color'] = "var(--c-selected-bigger-section-text)"
}

var onkeydown = (function (ev) {
  var key;
  var isShift;
  if (window.event) {
    key = window.event.keyCode;
    isShift = !!window.event.shiftKey; // typecast to boolean
  } else {
    key = ev.which;
    isShift = !!ev.shiftKey;
  }
  switch (key) {
    case 17: // ignore ctrl key
      break;
    case 37:
      if ( isShift ) {
        focusPreviousBiggerSection()
      }else
      {
        focusPreviousArticle()       
      }
      break;
    case 39:
      if ( isShift ) {
        focusNextBiggerSection()
      }else
      {
        focusNextArticle()
      }
      break;
    default:
      // alert(key);
      // do stuff here?
      break;
  }
});

$(document).ready(function () {
  
});


function addrow(){
  var table = document.getElementById("edit_table");
  var row = document.getElementById("edit_table").lastChild;
  var clone = row.cloneNode(true);
  table.appendChild(clone);
}