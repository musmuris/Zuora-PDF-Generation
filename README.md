# Zuora Quote PDF Generation

Out of the box, when generating a PDF, Zuora Quotes can only download the PDS or make them as attachments onto an opportunity.  We had requirements this didn't meet:
1. We wanted to attach the PDF to a Quote itself, not the Opportunity
2. We wanted public URLs to enable easy downloading of PDFs without a salesforce login
    1. You cannot make public facing URLs for attachments.
    2. Attachments are being deprecated in favour of files in Salesforce anyway
    3. Also files can be attached to many objects without duplication (originally we coppied the attachment to the quote from the opportunity)

After adding comments to [this idea](https://community.zuora.com/t5/Zuora-CPQ-Ideas/Zuora-Quote-PDFs-and-Salesforce-Files/idc-p/27821#!%2F%23M1653) and seeing replies there we wrote the code here (sanitized to remove some company specific bits)

There are 2 main parts to this which are a VisualForce page and controller to drive it, 
and a class that does the actual heavy lifting. This calls the Zuora APIs to generate a
PDF, then download that, save it as a Salesforce file and make a URL for it

There are also some auxiliary classes for testing etc.
and also a javascript button that we use to display the page in an iframe. Note that Salesforce Lightning doesn't allow Javascript buttons, so we'll have to find an alternative method when we finally move to that!

Most of the interesting stuff is in:

* [ZuoraGenerateQuotePdfController.cls](classes/ZuoraGenerateQuotePdfController.cls)
    * VF controller calls that drives the below
* [ZuoraQuoteDocumentUtil.cls](classes/ZuoraQuoteDocumentUtil.cls)
    * The actually useful bit



