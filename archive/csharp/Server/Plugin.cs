using Barotrauma.LuaCs;
using Barotrauma.LuaCs.Data;

namespace YourProject
{
    // Server-side C# entrypoint.
    // Enable this file in ModConfig.xml and CSharp/RunConfig.xml only when the
    // mod needs server C# code.
    public sealed class ServerPlugin : IAssemblyPlugin
    {
        public IConfigService ConfigService { get; set; }
        public IPluginManagementService PluginService { get; set; }
        public ILoggerService LoggerService { get; set; }

        public void Initialize() { }

        public void OnLoadCompleted() { }

        public void PreInitPatching() { }

        public void Dispose() { }
    }
}
