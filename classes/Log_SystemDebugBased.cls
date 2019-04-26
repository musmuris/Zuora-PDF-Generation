public class Log_SystemDebugBased implements ILog
{
    private static final Map<LogLevel, LoggingLevel>
        m_LogLevelToSystemLoggingLevel =
            new Map<LogLevel, LoggingLevel>
            {
                LogLevel.Debug => LoggingLevel.Debug,
                LogLevel.Info  => LoggingLevel.Info,
                LogLevel.Warn  => LoggingLevel.Warn,
                LogLevel.Error => LoggingLevel.Error
            };

    public void debug(String message)
    {
        log(LogLevel.Debug, message);
    }

    public void info(String message)
    {
        log(LogLevel.Info, message);
    }

    public void warn(String message)
    {
        log(LogLevel.Warn, message);
    }

    public void error(String message)
    {
        log(LogLevel.Error, message);
    }

    public void log(LogLevel level, String message)
    {
        LoggingLevel apexLoggingLevel =
            m_LogLevelToSystemLoggingLevel.get(level);

        System.debug(apexLoggingLevel, message);
    }
}