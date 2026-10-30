# Реестр доказательств

Дата: 2026-10-30. **E** — исполнено в изолированном host; **S** — исходники; **W** — обнаружено в установленном моде; **D** — документация; **U** — не проверено. E не означает проверку полного игрового процесса. Результаты E: [validation.md](validation.md).

Локальные исходники платформы: `C:/Users/limanchel/.cache/luacs-bridge-research/platform`; commit `c6e8829143c98162ed376aee33eb9799602365ac`. Файлы G — игровой код в этой сборке LuaCs, а не доказательство полного тождества upstream Barotrauma.

Форк runtime: подкаталог `Libraries/moonsharp`; commit `b556e550eb20b950a7db3ef69006104af3f654da`. Постоянные ссылки позволяют восстановить источники после очистки локального кеша.

## P1

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaUserDataService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaUserDataService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaUserDataService.cs`.

- [public IUserDataDescriptor RegisterType](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaUserDataService.cs#L81), строка 81.
- [public object CreateStatic](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaUserDataService.cs#L170), строка 170.
- [public DynValue CreateUserDataFromType](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaUserDataService.cs#L393), строка 393.
- [public void MakePropertyAccessible](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaUserDataService.cs#L294), строка 294.

## P2

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PluginManagementService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PluginManagementService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PluginManagementService.cs`.

- [public Type GetType](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PluginManagementService.cs#L345), строка 345.
- [p.Initialize()](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PluginManagementService.cs#L497), строка 497.
- [p.OnLoadCompleted()](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PluginManagementService.cs#L504), строка 504.

## P3

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/LuaScriptManagementService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/LuaScriptManagementService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/LuaScriptManagementService.cs`.

- [private void SetupEnvironment](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/LuaScriptManagementService.cs#L338), строка 338.
- [public DynValue? CallFunctionSafe](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/LuaScriptManagementService.cs#L593), строка 593.
- [public void OnAssemblyUnloading](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/LuaScriptManagementService.cs#L663), строка 663.

## P4

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/DefaultLuaRegistrar.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/DefaultLuaRegistrar.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/DefaultLuaRegistrar.cs`.

- [private void RegisterShared](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/DefaultLuaRegistrar.cs#L60), строка 60.

## P5

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaClasses/LuaConverters.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaClasses/LuaConverters.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaClasses/LuaConverters.cs`.

- [public void RegisterLuaConverters](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaClasses/LuaConverters.cs#L23), строка 23.
- [typeof(ulong)](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaClasses/LuaConverters.cs#L165), строка 165.
- [private void RegisterAction](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaClasses/LuaConverters.cs#L328), строка 328.

## P6

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/SafeLuaUserDataService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/SafeLuaUserDataService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/SafeLuaUserDataService.cs`.

- [private bool CanBeRegistered](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/SafeLuaUserDataService.cs#L74), строка 74.

## P7

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PackageManagementService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PackageManagementService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PackageManagementService.cs`.

- [public FluentResults.Result ExecuteLoadedPackages](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PackageManagementService.cs#L294), строка 294.
- [public FluentResults.Result StopRunningPackages](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/PackageManagementService.cs#L410), строка 410.

## P8

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigService.cs`.

- [ModConfig.xml](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigService.cs#L138), строка 138.
- [CSharp/Shared](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigService.cs#L308), строка 308.

## P9

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigFileParserService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigFileParserService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigFileParserService.cs`.

- [var isScript](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigFileParserService.cs#L65), строка 65.
- [GetRuntimeEnvironment](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/ModConfigFileParserService.cs#L66), строка 66.

## P10

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/EventService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/EventService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/EventService.cs`.

- [public void Add](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/EventService.cs#L106), строка 106.
- [public void Remove](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/EventService.cs#L202), строка 202.
- [public object Call](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/EventService.cs#L132), строка 132.

## P11

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaPatcherService.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaPatcherService.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaPatcherService.cs`.

- [LuaCsPatchFunc](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaPatcherService.cs#L23), строка 23.
- [Генерация вызова LuaCsPatchFunc.Invoke](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaPatcherService.cs#L528), строка 528; конвертер этого delegate находится в P5.

## P12

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/LuaCsSetup.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/LuaCsSetup.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/LuaCsSetup.cs`.

- [void RunStateRunning_OnExit](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/LuaCsSetup.cs#L410), строка 410.
- [public DynValue CallLuaFunction](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/LuaCsSetup.cs#L447), строка 447.

## P13

**S** — [Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Plugins/IAssemblyPlugin.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Plugins/IAssemblyPlugin.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Plugins/IAssemblyPlugin.cs`.

- [public interface IAssemblyPlugin](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Plugins/IAssemblyPlugin.cs#L6), строка 6.

## M1

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/StandardUserDataDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/StandardUserDataDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/StandardUserDataDescriptor.cs`.

- [private void FillMemberList](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/StandardUserDataDescriptor.cs#L46), строка 46.

## M2

**S** — [MoonSharp.Interpreter/Interop/BasicDescriptors/DispatchingUserDataDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/BasicDescriptors/DispatchingUserDataDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/BasicDescriptors/DispatchingUserDataDescriptor.cs`.

- [public virtual DynValue Index](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/BasicDescriptors/DispatchingUserDataDescriptor.cs#L218), строка 218.
- [public virtual bool SetIndex](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/BasicDescriptors/DispatchingUserDataDescriptor.cs#L326), строка 326.
- [public virtual DynValue MetaIndex](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/BasicDescriptors/DispatchingUserDataDescriptor.cs#L493), строка 493.
- [public virtual bool IsTypeCompatible](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/BasicDescriptors/DispatchingUserDataDescriptor.cs#L660), строка 660.

## M3

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/MethodMemberDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/MethodMemberDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/MethodMemberDescriptor.cs`.

- [public override DynValue Execute](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/MethodMemberDescriptor.cs#L177), строка 177.
- [public static bool CheckMethodIsCompatible](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/MethodMemberDescriptor.cs#L135), строка 135.

## M4

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/OverloadedMethodMemberDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/OverloadedMethodMemberDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/OverloadedMethodMemberDescriptor.cs`.

- [private DynValue PerformOverloadedCall](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/OverloadedMethodMemberDescriptor.cs#L147), строка 147.
- [private int CalcScoreForOverload](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/OverloadedMethodMemberDescriptor.cs#L305), строка 305.

## M5

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/MemberDescriptors/FunctionMemberDescriptorBase.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/MemberDescriptors/FunctionMemberDescriptorBase.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/MemberDescriptors/FunctionMemberDescriptorBase.cs`.

- [protected virtual object[] BuildArgumentList](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/MemberDescriptors/FunctionMemberDescriptorBase.cs#L131), строка 131.
- [protected static DynValue BuildReturnValue](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/MemberDescriptors/FunctionMemberDescriptorBase.cs#L239), строка 239.

## M6

**S** — [MoonSharp.Interpreter/Interop/Converters/ScriptToClrConversions.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/ScriptToClrConversions.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/Converters/ScriptToClrConversions.cs`.

- [internal static object DynValueToObject(](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/ScriptToClrConversions.cs#L38), строка 38.
- [internal static object DynValueToObjectOfType(](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/ScriptToClrConversions.cs#L119), строка 119.
- [internal static int DynValueToObjectOfTypeWeight](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/ScriptToClrConversions.cs#L289), строка 289.

## M7

**S** — [MoonSharp.Interpreter/Interop/Converters/ClrToScriptConversions.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/ClrToScriptConversions.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/Converters/ClrToScriptConversions.cs`.

- [internal static DynValue ObjectToDynValue](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/ClrToScriptConversions.cs#L103), строка 103.
- [public static DynValue EnumerationToDynValue](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/ClrToScriptConversions.cs#L184), строка 184.

## M8

**S** — [MoonSharp.Interpreter/Interop/Converters/TableConversions.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/TableConversions.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/Converters/TableConversions.cs`.

- [internal static bool CanConvertTableToType](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/TableConversions.cs#L45), строка 45.
- [internal static object ConvertTableToArrayOfGenericType](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/TableConversions.cs#L166), строка 166.

## M9

**S** — [MoonSharp.Interpreter/Interop/Converters/NumericConversions.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/NumericConversions.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/Converters/NumericConversions.cs`.

- [internal static object DoubleToType](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/Converters/NumericConversions.cs#L43), строка 43.

## M10

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/GenericMethodMemberDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/GenericMethodMemberDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/GenericMethodMemberDescriptor.cs`.

- [public override DynValue Execute](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/GenericMethodMemberDescriptor.cs#L190), строка 190.
- [protected override object[] BuildArgumentList](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/GenericMethodMemberDescriptor.cs#L246), строка 246.

## M11

**S** — [MoonSharp.Interpreter/Interop/UserDataRegistries/TypeDescriptorRegistry.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/UserDataRegistries/TypeDescriptorRegistry.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/UserDataRegistries/TypeDescriptorRegistry.cs`.

- [internal static IUserDataDescriptor GetDescriptorForType](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/UserDataRegistries/TypeDescriptorRegistry.cs#L247), строка 247.

## M12

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/EventMemberDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/EventMemberDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/EventMemberDescriptor.cs`.

- [public static bool CheckEventIsCompatible](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/EventMemberDescriptor.cs#L73), строка 73.
- [internal DynValue AddCallback](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/EventMemberDescriptor.cs#L175), строка 175.
- [internal DynValue RemoveCallback](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/EventMemberDescriptor.cs#L189), строка 189.
- [private void DispatchEvent](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/EventMemberDescriptor.cs#L273), строка 273.

## M13

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/FieldMemberDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/FieldMemberDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/FieldMemberDescriptor.cs`.

- [public void SetValue](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/FieldMemberDescriptor.cs#L156), строка 156.

## M14

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/PropertyMemberDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/PropertyMemberDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/PropertyMemberDescriptor.cs`.

- [public void SetValue](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/ReflectionMemberDescriptors/PropertyMemberDescriptor.cs#L236), строка 236.

## M15

**S** — [MoonSharp.Interpreter/Execution/VM/Processor/Processor_InstructionLoop.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Execution/VM/Processor/Processor_InstructionLoop.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Execution/VM/Processor/Processor_InstructionLoop.cs`.

- [catch (Exception ex)](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Execution/VM/Processor/Processor_InstructionLoop.cs#L249), строка 249.
- [private int ExecIndex](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Execution/VM/Processor/Processor_InstructionLoop.cs#L1206), строка 1206.

## M16

**S** — [MoonSharp.Interpreter/Execution/VM/Processor/Processor_IExecutionContext.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Execution/VM/Processor/Processor_IExecutionContext.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Execution/VM/Processor/Processor_IExecutionContext.cs`.

- [internal DynValue GetMetamethod](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Execution/VM/Processor/Processor_IExecutionContext.cs#L66), строка 66.

## M17

**S** — [MoonSharp.Interpreter/DataTypes/UserData.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/DataTypes/UserData.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/DataTypes/UserData.cs`.

- [public static DynValue Create(](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/DataTypes/UserData.cs#L227), строка 227.
- [public static DynValue CreateStatic(](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/DataTypes/UserData.cs#L260), строка 260.

## M18

**S** — [MoonSharp.Interpreter/CoreLib/ErrorHandlingModule.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/CoreLib/ErrorHandlingModule.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/CoreLib/ErrorHandlingModule.cs`.

- [public static DynValue pcall](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/CoreLib/ErrorHandlingModule.cs#L17), строка 17.
- [ShouldPCallCatchException](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/CoreLib/ErrorHandlingModule.cs#L73), строка 73.

## M19

**S** — [MoonSharp.Interpreter/DataTypes/Closure.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/DataTypes/Closure.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/DataTypes/Closure.cs`.

- [public DynValue Call](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/DataTypes/Closure.cs#L78), строка 78.
- [public Script OwnerScript](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/DataTypes/Closure.cs#L40), строка 40.

## M20

**S** — [MoonSharp.Interpreter/Interop/StandardDescriptors/StandardGenericsUserDataDescriptor.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/StandardGenericsUserDataDescriptor.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Interop/StandardDescriptors/StandardGenericsUserDataDescriptor.cs`.

- [public IUserDataDescriptor Generate](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Interop/StandardDescriptors/StandardGenericsUserDataDescriptor.cs#L70), строка 70.

## G1

**S** — [Barotrauma/BarotraumaClient/ClientSource/GUI/GUIButton.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIButton.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIButton.cs`.

- [public delegate bool OnClickedHandler](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIButton.cs#L15), строка 15.
- [if (OnClicked(this, UserData))](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIButton.cs#L299), строка 299.

## G2

**S** — [Barotrauma/BarotraumaShared/SharedSource/Map/Explosion.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Map/Explosion.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/Map/Explosion.cs`.

- [private static float GetObstacleDamageMultiplier](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Map/Explosion.cs#L777), строка 777.

## G3

**S** — [Barotrauma/BarotraumaShared/SharedSource/Items/Components/ItemContainer.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/ItemContainer.cs). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Barotrauma/BarotraumaShared/SharedSource/Items/Components/ItemContainer.cs`.

- [private readonly ImmutableArray<SlotRestrictions> slotRestrictions](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/ItemContainer.cs#L266), строка 266.

## M21

**S** — [MoonSharp.Interpreter/Script.cs](https://github.com/evilfactory/moonsharp/blob/b556e550eb20b950a7db3ef69006104af3f654da/MoonSharp.Interpreter/Script.cs#L445). Локально: `C:/Users/limanchel/.cache/luacs-bridge-research/platform/Libraries/moonsharp/MoonSharp.Interpreter/Script.cs`.

- `Call(DynValue, params DynValue[])`, строка 445: проверка принадлежности Script, прямой CLR callback либо VM call.
- `Call(DynValue, params object[])`, строка 486: каждый аргумент проходит `DynValue.FromObject(this, args[i])`.

## W2

**W/S** — globals платформы: `D:/SteamLibrary/steamapps/workshop/content/602960/2559634234/Lua/LuaSetup.lua:5–19` (`AddTableToGlobal`, `Descriptors = LuaUserData`); `Lua/DefaultLib/LibShared.lua:7–19` (`Int32`, `UInt64`, `Single` и другие static wrappers). Хеши фиксированы в W1. Это Lua-надстройка поверх зарегистрированных P4/P5 типов, а не встроенные слова Lua.

## D1

**D** — [руководство LuaCs](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/), [документация C#](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/html/index.html). Живые страницы не привязаны к версии; при расхождении вывод основан на S/E. Документируемый API LuaUserData также хранится в [luacs-docs/lua/lua/LuaUserData.lua](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/luacs-docs/lua/lua/LuaUserData.lua).

## W1

**W** — корень workshop `D:/SteamLibrary/steamapps/workshop/content/602960`; в [каталоге практик](mod-patterns.md) приведены относительные к нему пути, символы и строки. Версии модов: [инвентаризация](../../../../docs/features/luacs-interop/workshop-inventory.md); хеши всех Lua/C# файлов: [снимок](../../../../docs/features/luacs-interop/workshop-files.json).
