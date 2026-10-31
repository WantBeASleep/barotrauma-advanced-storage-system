using System;
using Barotrauma;

namespace YourProject
{
    public static class UrlOpener
    {
        // Opens a URL through Barotrauma's shell helper so callers do not depend
        // on platform-specific process launching details.
        public static void Open(string url)
        {
            if (string.IsNullOrWhiteSpace(url))
            {
                throw new ArgumentException("URL must not be empty.", nameof(url));
            }

            ToolBox.OpenFileWithShell(url);
        }
    }
}
