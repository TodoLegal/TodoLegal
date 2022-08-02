

(function(){
    //I get the element

    var divElem=document.getElementById('closeablecard');
    var isClicked=0;

    //divElem.style.display='block';

    divElem.addEventListener("click", () => {
      isClicked=1;
      console.log("Clicked!"+isClicked);
    });

    //I set css display to block so become visible
  

    //Via if condition I check the readystate status
     if (document.readyState === 'loading') {
     //If loading I set the following function to trigger when it becomes complete
     document.onreadystatechange=function(){

        if (document.readyState === 'complete' && isClicked == 0){
     //When it becomes complete the it triggers the setTimeout function (time set=3000ms)
        setTimeout(function(){
     //After the time is passed then I change the css display to block that appears the elements
          if (isClicked==0){
            console.log("NotClicked"+isClicked);
            divElem.style.display='none';  
          }   
       }, 10000);
       }
       };
     }    
       
    })();
  

       //console.log('Hello from My JS')