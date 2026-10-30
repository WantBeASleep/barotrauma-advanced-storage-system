using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;
using MoonSharp.Interpreter;
using MoonSharp.Interpreter.Interop;
using Barotrauma.LuaCs;

namespace BridgeProbes
{
    // Only assembly lookup is substituted. LuaUserDataService is the real workshop binary.
    public class TypeLookupProxy : DispatchProxy
    {
        protected override object Invoke(MethodInfo method, object[] args)
        {
            if (method.Name != "GetType") throw new NotSupportedException(method.Name);
            string name = (string)args[0];
            Type found = Type.GetType(name, false);
            if (found != null) return found;
            foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                found = assembly.GetType(name, false);
                if (found != null) return found;
            }
            return null;
        }
    }

    public static class Host
    {
        public static void Run(string demo, string probes)
        {
            UserData.RegisterType(typeof(LuaUserDataService));
            UserData.RegisterType(typeof(IUserDataDescriptor));
            UserData.RegisterType(typeof(Type));
            UserData.RegisterType(typeof(Exception));
            var lookup = DispatchProxy.Create<IPluginManagementService, TypeLookupProxy>();
            var service = new LuaUserDataService(lookup);
            var script = new Script();
            Script.GlobalOptions.ShouldPCallCatchException = ex => true;
            script.Options.DebugPrint = Console.WriteLine;
            script.Globals["LuaUserData"] = service;
            script.Globals["CSActive"] = true;
            script.DoString(File.ReadAllText(demo), null, "bridge-demo");
            script.DoString(File.ReadAllText(probes), null, "bridge-probes");
            service.Dispose();
        }
    }
}
