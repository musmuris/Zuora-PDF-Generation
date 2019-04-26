// We have this as a custom button on the zqu__Quote__c object

var buttonScope = buttonScope || {}; 

(function() {

    function generateQuote(url) { 
        var iframe = document.createElement("iframe"); 
        iframe.src = url; 
        iframe.style.height = "185px"; 
        iframe.style.width = "100%"; 
        iframe.style.marginTop = "15px";
        iframe.style.display = "block"; 
        iframe.style.border = "none"; 

        var divFrame = document.getElementById("divForPdfFrame");
        divFrame.appendChild(iframe);

        // Listens to event from IFrame to reload quote page when done
        window.addEventListener('message', function(event) {
            if( event.data == 'pdfcomplete')
                window.location.reload();
        }, false);

    }

    var pageURL = window.location.hostname; 

    function addDivForFrame() { 
        var divForFrame = document.createElement('div'); 
        divForFrame.id = "divForPdfFrame"; 
        divForFrame.style.width = "30%"; 
        divForFrame.style.height = "200px"; 
        divForFrame.style.background = "white"; 
        divForFrame.style.margin = "auto"; 
        divForFrame.style.position = "fixed"; 
        divForFrame.style.top = "25%"; 
        divForFrame.style.left = "35%"; 
        divForFrame.style.border = "thin solid black"; 
        document.getElementsByTagName('body')[0].appendChild(divForFrame); 
    } 

    buttonScope.onClickGenerateQuotePdf = function() { 
        addDivForFrame(); 
        generateQuote('https://'+pageURL+'/apex/ZuoraGenerateQuotePdf?quoteId={!zqu__Quote__c.Id}'); 
    } 

})(); 

buttonScope.onClickGenerateQuotePdf();
