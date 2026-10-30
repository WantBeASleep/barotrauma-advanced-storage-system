using System;
using System.Collections.Generic;
using MoonSharp.Interpreter;

namespace BridgeProbes
{
    public struct Point { public int X; }
    public interface INamed { string Name { get; } }
    public class Base { public string BaseName => "base"; }
    public sealed class Box : Base, INamed
    {
        public string Name { get; set; } = "box";
        public Point Position { get; set; }
        public readonly int Readonly = 3;
        public int ReadOnlyProperty => 4;
        public int PrivateSetter { get; private set; } = 5;
        public int Number;
        private int secret = 11;
        private int Hidden(int x) => secret + x;
        public static int StaticNumber = 8;
        public event Action<int> UnsupportedEvent;
        public void Fire() { UnsupportedEvent?.Invoke(1); }
    }
    public enum Mode { One = 1, Two = 2 }
    public static class Api
    {
        private static readonly List<int> values = new List<int> { 10, 20 };
        public static string Pick(int x) => "int";
        public static string Pick(double x) => "double";
        public static int Integer(int x) => x;
        public static int Optional(int x = 7) => x;
        public static string OptionalText(string x = "default") => x;
        public static int? Nullable(int? x) => x;
        public static string ObjectType(object x) => x?.GetType().FullName;
        public static int Sum(params int[] values) { int n = 0; foreach (int v in values) n += v; return n; }
        public static int RefOut(ref int x, out string label) { x += 2; label = "out"; return 9; }
        public static string Name(INamed x) => x.Name;
        public static Mode EnumEcho(Mode mode) => mode;
        public static T Echo<T>(T value) => value;
        public static T Constrained<T>(T value) where T : class => value;
        public static int CallFunc(Func<int, int> callback) => callback(4);
        public static int CallClosure(Closure callback) => callback.Call(4).ToObject<int>();
        public static List<int> List() => values;
        public static int ListSum(List<int> values) { int n = 0; foreach(int v in values) n += v; return n; }
        public static int DictionaryValue(Dictionary<string, int> values) => values["a"];
        public static void Fail() => throw new InvalidOperationException("probe-error");
        public static void Move(Point p) { p.X = 100; }
    }
}
