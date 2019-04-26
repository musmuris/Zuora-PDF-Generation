public class ZuoraApiRequestSender implements IZuoraApiRequestSender
{
    private Zuora.ZApi m_zApiInstance = null;
    public HttpResponse sendRequest(HttpRequest request)
    {   
        if( m_zApiInstance == null )
            m_zApiInstance = new Zuora.ZApi();

        return m_zApiInstance.sendRequest(request);
    }
}