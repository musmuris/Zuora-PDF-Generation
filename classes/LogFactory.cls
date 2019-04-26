public class LogFactory
{
    public static ILog CreateDefaultLog()
    {
        return new Log_SystemDebugBased();
    }
}