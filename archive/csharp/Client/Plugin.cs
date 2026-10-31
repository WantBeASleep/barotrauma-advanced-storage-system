using Barotrauma.LuaCs;
using Barotrauma.LuaCs.Data;

namespace YourProject
{
    // Client-side C# entrypoint.
    // Replace "YourProject" with your mod's C# namespace before release.
    public sealed class ClientPlugin : IAssemblyPlugin
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
