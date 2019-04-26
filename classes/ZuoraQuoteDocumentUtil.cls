public class ZuoraQuoteDocumentUtil 
{
    private final ILog m_Log;
    private final IZuoraApiRequestSender m_ZuoraApiRequestSender;
    public ZuoraQuoteDocumentUtil( IZuoraApiRequestSender requestSender, ILog log )
    {
        m_ZuoraApiRequestSender = requestSender;
        m_Log = log;
    }
    
    public string generatePdfForQuote(Id quoteId) 
    {
        HttpRequest request = buildZuoraRequest('POST', '/v1/quotes/document');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        String jsonBody = buildGenPdfJson(quoteId);

        request.setBody(jsonBody);

        HttpResponse resp = m_ZuoraApiRequestSender.sendRequest(request);
        
        m_Log.debug(String.valueOf(resp));
        m_Log.debug(resp.getBody());

        if( resp.getStatusCode() != HttpStatusCode.OK )
        {
            throw new ZuoraApiException(
                'There was an error generating the PDF. HTTP Code was ' 
                + resp.getStatusCode());           
        }
        
        Map<String, Object> bodyJson = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
        m_Log.debug(String.valueOf(bodyJson));
        if( bodyJson.get('success') != true )
        {
            throw new ZuoraApiException( 
                'There was an error generating the PDF. Zuora success was false' );
        }

        if( !bodyJson.containsKey('file') )
        {
            throw new ZuoraApiException( 
                'There was an error generating the PDF. Zuora did not return a valid file' );
        }

        return (String)bodyJson.get('file');
    }

    public ContentVersion downloadPdfUrlAndAttachToQuote(String fileUrl, Id quoteId)
    {        
        HttpRequest request = buildZuoraRequest('GET', fileUrl);

        HttpResponse resp = m_ZuoraApiRequestSender.sendRequest(request);
        
        m_Log.debug(String.valueOf(resp));
        if( resp.getStatusCode() != HttpStatusCode.OK )
        {
            throw new ZuoraApiException(
                'There was an error downloading the PDF. HTTP Code was '
                + resp.getStatusCode() );
        }

        Blob body = resp.getBodyAsBlob();        

        String pdfName = buildPdfFileName(quoteId);

        ContentVersion contentVersion = new ContentVersion(
            ContentLocation = 'S',  // S means stored in Salesforce. 
            VersionData = body,
            Title = pdfName,
            PathOnClient = pdfName
            );
            insert contentVersion;

        Id contentDocumentId = [SELECT ContentDocumentId
                                FROM ContentVersion
                                WHERE Id = : contentVersion.id ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentid,
            LinkedEntityId = quoteId,
            ShareType = 'I' 
        );

        insert cdl;

        GeneratePublicLink(contentVersion, quoteId);

        return contentVersion;
    }

    private String GeneratePublicLink(ContentVersion contentVersion, Id quoteId )
    {                   
        ContentDistribution cd = new ContentDistribution(
            Name = contentVersion.Title,
            ContentVersionId = contentVersion.Id,
            PreferencesAllowOriginalDownload = true,
            PreferencesAllowViewInBrowser = true,
            PreferencesNotifyOnVisit = false,
            PreferencesNotifyRndtnComplete = false
        );
        insert cd;
            
        String publicUrl = [SELECT ContentDownloadUrl
                            FROM ContentDistribution
                            WHERE Id = :cd.Id].ContentDownloadUrl;
       
        // In Our case we wanted to have a nicer URL under our company's 
        // domain - so here we munged the link and used NGINX to proxy
        // the download. BASE Url is actually from a custom setting
        //
        // String quotesSite = 'https://quotes.my.company';
        // Url sfPublicUrl = new Url(publicUrl);
        // String quotesUrl = 'https://' + 
        //     quotesSite + '/?' +  
        //     sfPublicUrl.getQuery().replace('&asPdf=false','');
        // 
        // m_Log.debug('Public URL is ' + quotesUrl);

        // zqu__Quote__c quote = new zqu__Quote__c( 
        //     Id = quoteId, 
        //     Latest_PDF_Link__c = quotesUrl
        // );
        // update quote;        
        //
        // return quotesUrl;

        return publicUrl;
    }


    private string buildGenPdfJson(Id quoteId)
    {
        String sessid = UserInfo.getSessionId();

        String partnerUrl = 
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/Soap/u/10.0/' + 
            UserInfo.getOrganizationId();
        
        Map<String,String> reqJson = new Map<String,String>();        
        reqJson.put('documentType', 'pdf');
        reqJson.put('locale', 'en_US');
        reqJson.put('quoteId', quoteId);
        reqJson.put('serverUrl', partnerUrl);
        reqJson.put('sessionId', sessid);
        reqJson.put('templateId', getTemplateIdForQuote(quoteId));
        reqJson.put('useSFDCLocale', '1');
        reqJson.put('zquotesMajorVersion', '9');
        reqJson.put('zquotesMinorVersion', '8');        
        String jsonBody = JSON.serialize(reqJson);

        m_Log.debug('JSON: ' + jsonBody);

        return jsonBody;
    }

    private HttpRequest buildZuoraRequest(String method, String endpoint)
    {
        String hostName = 
            UserInfo.getOrganizationId() == '<production ORGId>' ? 'rest.eu.zuora.com' 
                                                                 : 'rest.sandbox.eu.zuora.com';
        string zuoraApiUrl = 'https://' + hostName + endpoint;
        m_Log.debug('Zuora URL: ' + zuoraApiUrl);                
        HttpRequest request = new HttpRequest();
        request.setEndpoint(zuoraApiUrl);
        request.setMethod(method);

        // Default is 10 seconds. Max is 120 seconds
        // Using 30 seconds (but in ms)        
        request.setTimeout(30000);
        
        return request;
    }

    @TestVisible
    private static String getTemplateIdForQuote(Id quoteId)
    {
        // First get one defined on the quote
        List<zqu__Quote__c> quotes = [ SELECT Id,
                                       zqu__QuoteTemplate__c,
                                       zqu__SubscriptionType__c
                                FROM zqu__Quote__c
                                WHERE Id = :quoteId ];

        if( quotes.size() == 0 )
            throw new InvalidQuoteException('Quote with ID ' + quoteId + ' was not found');
        
        if( quotes[0].zqu__QuoteTemplate__c != null )
            return [SELECT zqu__Template_Id__c
                    FROM zqu__Quote_Template__c
                    WHERE Id = :quotes[0].zqu__QuoteTemplate__c]
                    .zqu__Template_Id__c;
        
        return [SELECT zqu__Template_Id__c
                FROM zqu__Quote_Template__c
                WHERE zqu__Quote_Type__c = :quotes[0].zqu__SubscriptionType__c
                    AND zqu__IsDefault__c = true ]
                .zqu__Template_Id__c;
    }

    private String buildPdfFileName(Id quoteId) 
    {
        zqu__Quote__c quote = [ SELECT Id, Name                                       
                                FROM zqu__Quote__c
                                WHERE Id = :quoteId ];

        if( quote == null )
            throw new InvalidQuoteException('Quote with ID ' + quoteId + ' was not found');

        string nowGmtString = Datetime.now().formatGmt('yyyyMMddHHmmss');

        return quote.Name + '_' + nowGmtString + '.pdf';
    }
}