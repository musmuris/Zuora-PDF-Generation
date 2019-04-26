public class ZuoraGenerateQuotePdfController
{ 
    public Id quoteId { get; set; }
    public String status { get; private set; }    
    public String errorMessage { get; private set; }

    public String zuoraPdfUrl { get; private set; }
    
    private final ILog m_Log;
    private final ZuoraQuoteDocumentUtil m_docUtil;
    
    public ZuoraGenerateQuotePdfController() 
    {                
        m_Log = LogFactory.CreateDefaultLog();
        m_Log.debug('ZuoraGenerateQuotePdfController()');

        m_docUtil = new ZuoraQuoteDocumentUtil( new ZuoraApiRequestSender(), m_Log );        
        status = 'initialized';
    }

    public PageReference generatePdf()
    {
        m_Log.debug('Will generate for ' + quoteId);
        try
        {
            zuoraPdfUrl = m_docUtil.generatePdfForQuote(quoteId);
            status = 'generated';
        }
        catch( Exception ex )
        {
            m_Log.error('Exception getting JSON ' + ex.getMessage());
            errorMessage = 'There was an error generating the PDF. ' + ex.getMessage();
        }

        return null; // Re-render same page
    }

    public PageReference downloadPdf()
    {        
        m_Log.debug('Will download ' + zuoraPdfUrl);
        
        try
        {
            m_docUtil.downloadPdfUrlAndAttachToQuote(zuoraPdfUrl, quoteId);
            status = 'downloaded';
        }
        catch( Exception ex )
        {
            m_Log.error('Exception downloading PDF ' + ex.getMessage());
            errorMessage = 'There was an error downloading the PDF. ' + ex.getMessage();
        }

        return null;
    }
}