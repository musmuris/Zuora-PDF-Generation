@isTest  
private class ZuoraQuoteDocumentUtilTest {

	@isTest
	static void generatePdfForQuote_makes_correct_httprequest()
    {
        Id quoteId = insertTestQuote();

        Map<String,Object> responseMap = new Map<String,Object>{
            'success' => true,
            'file' => 'http://this.would.be.a.file/file.pdf/'
        };
        
        Test.startTest();        

        StubZuoraApiRequestSender sender = 
            new StubZuoraApiRequestSender(HttpStatusCode.OK,
                                          JSON.serialize(responseMap) );

        ZuoraQuoteDocumentUtil util = new ZuoraQuoteDocumentUtil(
            sender,
            new CapturingLog() );

        String fileUrl = util.generatePdfForQuote(quoteId);

        Test.stopTest();

        System.assertEquals('http://this.would.be.a.file/file.pdf/', fileUrl);

        Map<String,Object> requestJson = (Map<String,Object>)JSON.deserializeUntyped(sender.RequestBody);

        System.assertEquals('abcd123', requestJson.get('templateId'));
        System.assertEquals(quoteId, requestJson.get('quoteId'));
	}

    @isTest
	static void generatePdfForQuote_throws_on_false_response()
    {
        Id quoteId = insertTestQuote();

        Map<String,Object> responseMap = new Map<String,Object>{
            'success' => false          
        };
        
        Test.startTest();                
        try
        {
            ZuoraQuoteDocumentUtil util = new ZuoraQuoteDocumentUtil(
                new StubZuoraApiRequestSender(HttpStatusCode.OK, JSON.serialize(responseMap) ),
                new CapturingLog() );
            util.generatePdfForQuote(quoteId);

            System.assert(false, 'No exception caught');
        }
        catch( ZuoraApiException ex )
        {}        
        
        Test.stopTest();        
	}

    @IsTest
    static void generatePdfForQuote_throws_on_no_quote()
    {                
        Id quoteId = insertTestQuote();
        delete new zqu__Quote__c(Id=quoteId);

        Test.startTest();        
        try
        {
            ZuoraQuoteDocumentUtil util = new ZuoraQuoteDocumentUtil(
                new StubZuoraApiRequestSender(HttpStatusCode.OK, '' ),
                new CapturingLog() );
            util.generatePdfForQuote(quoteId);

            System.assert(false, 'No exception caught');
        }
        catch( InvalidQuoteException ex )
        {
        }        
        Test.stopTest();
	}

    @IsTest
    static void generatePdfForQuote_throws_on_non_OK_response()
    {
        Id quoteId = insertTestQuote();

        Test.startTest();        
        try
        {
            ZuoraQuoteDocumentUtil util = new ZuoraQuoteDocumentUtil(
                new StubZuoraApiRequestSender(HttpStatusCode.BadRequest, '' ),
                new CapturingLog() );
            util.generatePdfForQuote(quoteId);
            System.assert(false, 'No exception caught');
        }
        catch( ZuoraApiException ex )
        {
        }        
        Test.stopTest();
	}

    @IsTest
    static void getTemplateIdForQuote_returns_default_template()
    {
        zqu__Quote_Template__c template = new zqu__Quote_Template__c(
            zqu__Quote_Type__c = 'New Subscription',
            zqu__Template_Id__c = 'abcd123',
            zqu__IsDefault__c = true
        );
        insert template;
        template = new zqu__Quote_Template__c(
            zqu__Quote_Type__c = 'Renew Subscription',
            zqu__Template_Id__c = 'efgh456',
            zqu__IsDefault__c = true
        );
        insert template;
        template = new zqu__Quote_Template__c(
            zqu__Quote_Type__c = 'Renew Subscription',
            zqu__Template_Id__c = 'ijkl789',
            zqu__IsDefault__c = false
        );
        insert template;
        
        zqu__Quote__c testQuote = new zqu__Quote__c(
            Name = 'foo',            
            zqu__SubscriptionType__c = 'Renew Subscription'
        );

        insert testQuote;
   
        System.assertEquals( 
            'efgh456', 
            ZuoraQuoteDocumentUtil.getTemplateIdForQuote(testQuote.Id) );
    }

    @IsTest
    static void downloadPdfUrlAndAttachToQuote_downloads_file() 
    {
        Id quoteId = insertTestQuote();
        String testUrl = 'http://fake.url/to/file.pdf';

        
        Test.startTest();

        StubZuoraApiRequestSender sender = 
            new StubZuoraApiRequestSender(HttpStatusCode.OK,
                                          'testbody' );

        ZuoraQuoteDocumentUtil util = new ZuoraQuoteDocumentUtil(
            sender,
            new CapturingLog() );

        util.downloadPdfUrlAndAttachToQuote(testUrl, quoteId);

        Test.stopTest();

        
        ContentDocumentLink doc = [SELECT ContentDocumentId 
                                   FROM ContentDocumentLink
                                   WHERE LinkedEntityId = :quoteId];

        ContentVersion ver = [SELECT Id, VersionData 
                              FROM ContentVersion
                              WHERE ContentDocumentId = :doc.ContentDocumentId];

        // If this passes then the file was download AND attached to the quote
        System.assertEquals('testbody', ver.VersionData.toString());
    }

    @IsTest
    static void downloadPdfUrlAndAttachToQuote_throws_on_non_OK_response()
    {
        Id quoteId = insertTestQuote();
        String testUrl = 'http://fake.url/to/file.pdf';

        
        Test.startTest();

        Boolean gotException = false;
        try
        {
           StubZuoraApiRequestSender sender = 
                new StubZuoraApiRequestSender(HttpStatusCode.BadRequest,'');

            ZuoraQuoteDocumentUtil util = new ZuoraQuoteDocumentUtil(
                sender,
                new CapturingLog() );
        
            util.downloadPdfUrlAndAttachToQuote(testUrl, quoteId);
        }
        catch( ZuoraApiException ex )
        {
            gotException = true;
        }        

        Test.stopTest();

        System.assert(gotException, 'Expected exception');
    }

    static Id insertTestQuote() 
    {
        zqu__Quote_Template__c template = new zqu__Quote_Template__c(
            zqu__Quote_Type__c = 'New Subscription',
            zqu__Template_Id__c = 'abcd123'
        );
        insert template;

        zqu__Quote__c testQuote = new zqu__Quote__c(
            Name = 'foo',
            zqu__QuoteTemplate__c = template.Id,
            zqu__SubscriptionType__c = 'New Subscription'
        );

        insert testQuote;
        return testQuote.Id;
    }


    private class StubZuoraApiRequestSender implements IZuoraApiRequestSender
    {
        private Integer m_Code;
        private String m_Body;
        public String RequestBody {get; private set;}
        public StubZuoraApiRequestSender(Integer code, String body)
        {
            m_Code = code;
            m_Body = body;
        }

        public HttpResponse sendRequest(HttpRequest request)
        {
            System.debug(request);
            RequestBody = request.getBody();
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(m_code);
            resp.setBody(m_Body);      
            return resp;
        }        
    }

    private class CapturingLog implements ILog
    {
        public void debug(String message) { log(LogLevel.Debug, message); }
        public void info(String message) { log(LogLevel.Info, message); }
        public void warn(String message) { log(LogLevel.Info, message); }
        public void error(String message) { log(LogLevel.Error, message); }
        
        public void log(LogLevel level, String message)
        {
            String captured = String.valueOf(level) + ': ' + message + '\n';
            System.debug(captured);
            CapturedMessage += captured;
        }

        public String CapturedMessage = '';        
    }
}