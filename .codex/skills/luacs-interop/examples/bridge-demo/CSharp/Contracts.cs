using System;
using MoonSharp.Interpreter;

namespace BridgeDemo
{
    public sealed class Address
    {
        public string Label { get; set; } = "";
    }

    public sealed class Line
    {
        public string Name { get; set; } = "";
        public int Quantity { get; set; }
        public Line() { }
        public Line(string name, int quantity) { Name = name; Quantity = quantity; }
    }

    public sealed class Request
    {
        public Address Destination { get; set; }
        public Line[] Lines { get; set; } = Array.Empty<Line>();
        public int? Limit { get; set; }
    }

    public sealed class Result
    {
        public string Label { get; set; } = "";
        public int Total { get; set; }
        public Line[] Lines { get; set; } = Array.Empty<Line>();
    }

    public static class Api
    {
        public static Line CreateLine(string name, int quantity)
        {
            if (quantity < 0) throw new ArgumentOutOfRangeException(nameof(quantity));
            return new Line(name, quantity);
        }

        public static Result Process(Request request)
        {
            if (request == null || request.Destination == null || request.Lines == null)
                throw new ArgumentException("request, Destination and Lines are required");
            int total = 0;
            foreach (Line line in request.Lines)
            {
                if (line == null || line.Quantity < 0)
                    throw new ArgumentException("Lines must contain non-null lines with Quantity >= 0");
                total = checked(total + line.Quantity);
            }
            if (request.Limit.HasValue && total > request.Limit.Value)
                throw new ArgumentException("Limit exceeded");
            return new Result { Label = request.Destination.Label, Total = total, Lines = request.Lines };
        }

        // Synchronous, one-shot callback: no retained Closure and no worker thread.
        public static int ProcessAndNotify(Request request, Closure callback)
        {
            if (callback == null) throw new ArgumentNullException(nameof(callback));
            Result result = Process(request);
            return callback.Call(result).ToObject<int>();
        }

        // Explicit adapter: this is application code, not automatic DTO mapping.
        public static Line LineFromTable(Table input)
        {
            if (input == null) throw new ArgumentNullException(nameof(input));
            DynValue name = input.Get("name");
            DynValue quantity = input.Get("quantity");
            if (name.Type != DataType.String || quantity.Type != DataType.Number ||
                double.IsNaN(quantity.Number) || double.IsInfinity(quantity.Number) ||
                quantity.Number < 0 || quantity.Number > int.MaxValue ||
                quantity.Number != Math.Truncate(quantity.Number))
                throw new ArgumentException("expected name:string and quantity:non-negative integer");
            return CreateLine(name.String, (int)quantity.Number);
        }
    }

    public sealed class Publisher : IDisposable
    {
        public event Action<Result> Completed;
        private bool disposed;
        public void Publish(Result result)
        {
            if (disposed) throw new ObjectDisposedException(nameof(Publisher));
            Completed?.Invoke(result);
        }
        public void Dispose() { Completed = null; disposed = true; }
    }
}
