function colapseIndice() {
  $('#sidebar').removeClass('active');
  $('.overlay').removeClass('active');
}

/* Tabs navigation */
var sticky_header = null
var active_tab = "#articulos"
window.onscroll = function() {onScrollCallback()};

// Phase 1 adaptation: stable position-based structure IDs (bs_*). We now derive navigation indexes dynamically.
var bigger_sections = [];
var article_names = document.getElementsByClassName("article-name");

function indexStructureAndArticles() {
  // Collect and sort structure by data-structure-position (numeric)
  bigger_sections = Array.from(document.querySelectorAll('.bigger-section'))
    .sort(function(a, b) {
      return parseInt(a.dataset.structurePosition || '0') - parseInt(b.dataset.structurePosition || '0');
    });
  // Assign navIndex to each bigger section
  bigger_sections.forEach(function(el, idx){ el.dataset.navIndex = idx; });

  // Map articles to nearest preceding bigger section
  var allArticles = Array.from(document.querySelectorAll('.article, .article-p'));
  var lastSectionIndex = null;
  allArticles.forEach(function(a){
    // Find previous sibling bigger section walking backwards
    var prev = a.previousElementSibling;
    while(prev && !prev.classList.contains('bigger-section')) {
      prev = prev.previousElementSibling;
    }
    if(prev && prev.classList.contains('bigger-section')) {
      lastSectionIndex = prev.dataset.navIndex;
    }
    // Persist mapping for navigation
    if(lastSectionIndex !== null) {
      a.dataset.sectionIndex = lastSectionIndex;
    }
  });
}

// Re-index on initial load and after any Turbo stream that appends structure/articles
document.addEventListener('turbo:load', indexStructureAndArticles);
document.addEventListener('turbo:before-stream-render', function(){
  setTimeout(indexStructureAndArticles, 0);
});
document.addEventListener('turbo:render', function(){
  setTimeout(indexStructureAndArticles, 0);
});

function setStickySectionHeading(header_text)
{
  document.getElementById('sticky_nav_header').innerText = header_text
}

function onScrollCallback()
{
  if(active_tab == "#articulos")
  {
    var sticky_elements = bigger_sections
    if(bigger_sections.length == 0)
      sticky_elements = article_names
    for(var i=0; i<sticky_elements.length; i++)
    {
      if (sticky_elements[i].offsetTop != 0 && sticky_elements[i].offsetTop - 1 <= window.pageYOffset)
      {
        sticky_header = sticky_elements[i]
      }
    }
    if(sticky_header && bigger_sections.length > 0)
      setStickySectionHeading(sticky_header.innerText)
  }
}

$('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
  var target = $(e.target).attr('href')
  if(sticky_header && bigger_sections.length > 0)
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

if(highlighted_count > 0){
  highlighted_count = highlighted_count / 2; 
  updateHighlightedView()
}

function updateHighlightedView()
{
  document.getElementById("result-count-big").innerText = (currrent_highlighted + 1) +" de "+highlighted_count
  element_highlighted = document.getElementsByClassName('highlighted')[currrent_highlighted]
  console.log(currrent_highlighted)
  console.log(element_highlighted)
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

var current_article = -1
var article_focused = null
var article_clicked = true

var articles_element = document.getElementsByClassName('article')

function unselectCurrentArticle()
{
  current_article = -1
  article_focused = null
}

function onClickBody()
{
  if(!article_clicked)
  {
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
    unselectCurrentArticle()
  }else
  {
    article_clicked = false
  }
}

function getArticleElementByIndex(idx) {
  var el = document.getElementById('article_idx_' + idx);
  if(el) return el;
  return document.querySelector('[data-article-global-index="' + idx + '"]');
}

function safeSelectArticle(el) {
  if(!el) return;
  el.scrollIntoView({block: 'center'});
  el.style['background-color'] = "var(--c-selected-article-background)";
  el.style['color'] = "var(--c-selected-article-text)";
}

function restoreArticleStyles(el) {
  if(!el) return;
  el.style['background-color'] = "var(--c-original-background)";
  el.style['color'] = "var(--c-original-text)";
}

function onClickArticle(clicked_article_id) {
  var newEl = getArticleElementByIndex(clicked_article_id);
  if(article_focused && article_focused !== newEl) {
    restoreArticleStyles(article_focused);
  }
  if(current_article !== clicked_article_id) {
    current_article = clicked_article_id;
    article_focused = newEl;
    safeSelectArticle(article_focused);
  } else {
    restoreArticleStyles(article_focused);
    unselectCurrentArticle();
  }
  article_clicked = true;
  return true;
}

function gotoArticle(article_number)
{
  if (bigger_section_focused)
  {
    var lastIdx = parseInt(bigger_section_focused.dataset.lastArticleIndex || '-1')
    current_article = lastIdx
    bigger_section_focused.style['background-color'] = "var(--c-original-background)"
    bigger_section_focused.style['color'] = "var(--c-original-text)"
    bigger_section_focused = null
  } else if(article_focused)
  {
    article_focused.style['background-color'] = "var(--c-original-background)"
    article_focused.style['color'] = "var(--c-original-text)"
  }

  current_article = article_number
  
  article_focused = getArticleElementByIndex(current_article)
  article_focused.scrollIntoView({block: 'center'})
  article_focused.style['background-color'] = "var(--c-selected-article-background)"
  article_focused.style['color'] = "var(--c-selected-article-text)"
}

function focusPreviousArticle()
{
  if (bigger_section_focused)
  {
    var lastIdx = parseInt(bigger_section_focused.dataset.lastArticleIndex || '-1')
    current_article = lastIdx
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
  
  article_focused = getArticleElementByIndex(current_article)
  article_focused.scrollIntoView({block: 'center'})
  article_focused.style['background-color'] = "var(--c-selected-article-background)"
  article_focused.style['color'] = "var(--c-selected-article-text)"
}

function focusNextArticle()
{
  if (bigger_section_focused)
  {
    var nextIdx = parseInt(bigger_section_focused.dataset.nextArticleIndex || '-1')
    current_article = nextIdx
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

  article_focused = getArticleElementByIndex(current_article)
  article_focused.scrollIntoView({block: 'center'})
  article_focused.style['background-color'] = "var(--c-selected-article-background)"
  article_focused.style['color'] = "var(--c-selected-article-text)"
}

/* Bigger section navigation */

var current_bigger_section = -1;
var bigger_section_focused = null;

function focusPreviousBiggerSection() {
  // Initialize if not set
  if(current_bigger_section === -1 && bigger_sections.length > 0) {
    current_bigger_section = bigger_sections.length - 1;
  } else {
    current_bigger_section -= 1;
    if(current_bigger_section < 0) current_bigger_section = bigger_sections.length - 1;
  }
  if(article_focused) { restoreArticleStyles(article_focused); unselectCurrentArticle(); }
  if(bigger_section_focused) { restoreArticleStyles(bigger_section_focused); }
  bigger_section_focused = bigger_sections[current_bigger_section];
  safeSelectArticle(bigger_section_focused);
}

function focusNextBiggerSection() {
  if(current_bigger_section === -1 && bigger_sections.length > 0) {
    current_bigger_section = 0;
  } else {
    current_bigger_section += 1;
    if(current_bigger_section >= bigger_sections.length) current_bigger_section = 0;
  }
  if(article_focused) { restoreArticleStyles(article_focused); unselectCurrentArticle(); }
  if(bigger_section_focused) { restoreArticleStyles(bigger_section_focused); }
  bigger_section_focused = bigger_sections[current_bigger_section];
  safeSelectArticle(bigger_section_focused);
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

$(window).on('load',function(){
  $('#modalCreateBasicAccount').modal('show');
});