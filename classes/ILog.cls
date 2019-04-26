public interface ILog // with convenience overloads
{
    void debug(String message);

    void info(String message);

    void warn(String message);

    void error(String message);

    void log(LogLevel level, String message);
}