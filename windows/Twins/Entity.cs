using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.Serialization;
using System.Reflection;

namespace Twins
{
    // Event delegate for outgoing payload events.
    public delegate void PayloadDelegate(IDictionary<string, object> payload);

    // Exception raised when an incoming payload contains invalid data.
    [Serializable]
    public class PayloadException : Exception
    {
        public PayloadException(string message)
            : base(message)
        { }

        protected PayloadException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        { }
    }

    public static class StringExtensions
    {
        // transforms names like fooBar into C#-style FooBar
        public static string ToCamelCase(this string str)
        {
            return str.Substring(0, 1).ToUpperInvariant() + str.Substring(1);
        }

        // does not really do anything, but kind of highlights the fact that the code relies on incoming keys being camelCase already
        public static string ToLowerCamelCase(this string str)
        {
            return str;
        }
    }

    // A facet provides a platform-independent JSON interface to a native object.
    // It turns incoming JSON payloads into native object setters/method calls,
    // and sends outgoing JSON payloads when native events occur.
    public interface IFacet
    {
        void AddedTo(Entity entity);
        void Set(Dictionary<string, object> properties);
        bool TryInvoke(string name, object[] args, PayloadDelegate reply);
        bool TryResolve(string name, Dictionary<string, object> payload, out object obj);
    }

    // Default base class for the facets
    public class Facet<NativeObj> : IFacet
    {
        protected readonly Entity entity;
        protected readonly NativeObj obj;

        public Facet(Entity entity, NativeObj obj)
        {
            this.entity = entity;
            this.obj = obj;
        }

        public virtual void AddedTo(Entity entity) {
        }
        
        public virtual void Set(Dictionary<string, object> properties)
        {
            // properties will be mutated inside the loop, hence ToArray
            foreach (var entry in properties.ToArray())
            {
                if (TrySet(entry.Key, entry.Value))
                    properties.Remove(entry.Key);
            }
        }

        // The default implementation tries to invoke a public method of this facet.
        public virtual bool TryInvoke(string name, object[] args, PayloadDelegate reply)
        {
            MethodInfo method = GetType().GetMethod(name, BindingFlags.Public | BindingFlags.Instance);
            if (method != null)
            {
                if (reply != null)
                    args = args.Concat(new object[] { reply }).ToArray();
                method.Invoke(this, args);
                return true;
            }
            return false;
        }

        // The default implementation tries to access public properties of this facet.
        protected virtual bool TrySet(string key, object value)
        {
            PropertyInfo prop = GetType().GetProperty(key.ToCamelCase());
            if (prop != null)
            {
                prop.SetValue(this, value, null);
                return true;
            }

            return false;
        }

        // The default implementation tries to access a public property of this facet.
        public virtual bool TryResolve(string name, Dictionary<string, object> payload, out object resolved)
        {
            resolved = null;

            PropertyInfo prop = GetType().GetProperty(name.ToCamelCase());
            if (prop != null)
            {
                resolved = prop.GetValue(this, null);
                return (resolved != null);
            }

            return false; 
        }
    }

    // Tries to access public properties, public or non-public fields and public methods of the native object.
    public class ReflectionFacet : Facet<object>
    {
        public ReflectionFacet(Entity entity, object obj)
            : base(entity, obj)
        {
        }

        public override bool TryInvoke(string name, object[] args, PayloadDelegate reply)
        {
            MethodInfo method = obj.GetType().GetMethod(name, BindingFlags.Public | BindingFlags.Instance);
            if (method != null)
            {
                if (reply != null)
                    args = args.Concat(new object[] { reply }).ToArray();
                method.Invoke(obj, args);
                return true;
            }
            return false;
        }

        protected override bool TrySet(string key, object value)
        {
            PropertyInfo prop = obj.GetType().GetProperty(key.ToCamelCase());
            if (prop != null)
            {
                prop.SetValue(obj, value, null);
                return true;
            }

            FieldInfo field = obj.GetType().GetField(key.ToLowerCamelCase());
            if (field != null)
            {
                field.SetValue(obj, value);
                return true;
            }

            return false;
        }

        public override bool TryResolve(string name, Dictionary<string, object> payload, out object resolved)
        {
            resolved = null;

            PropertyInfo prop = obj.GetType().GetProperty(name.ToCamelCase());
            if (prop != null)
            {
                resolved = prop.GetValue(obj, null);
                return (resolved != null);
            }

            FieldInfo field = obj.GetType().GetField(name.ToLowerCamelCase(), BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (field != null)
            {
                resolved = field.GetValue(obj);
                return (resolved != null);
            }

            return false;
        }
    }

    // Entity represents a single exposed object, and holds information about its exposed children.
    public abstract class Entity
    {
        private readonly List<IFacet> facets = new List<IFacet>();
        private readonly Dictionary<string, ChildEntity> children = new Dictionary<string, ChildEntity>();

        public Entity() { }

        public abstract RootEntity Root { get; }
        public abstract string Path { get; }
        public abstract string PathPrefix { get; }
        
        public void AddFacet(IFacet facet)
        {
            facets.Insert(0, facet);
            facet.AddedTo(this);
        }

        public void AddNativeObject(object obj) {
            AddFacet(new ReflectionFacet(this, obj));
        }

        public ChildEntity Expose(string name, object obj)
        {
            ChildEntity entity;
            if (!children.TryGetValue(name, out entity))
            {
                entity = new ChildEntity(this, name, obj);

                foreach (FacetRegistration reg in Root.facetRegistrations)
                {
                    IFacet facet;
                    if (reg.TryCreate(entity, out facet))
                        entity.AddFacet(facet);
                }

                children.Add(name, entity);
            }
            else if (entity.obj != obj)
            {
                throw new ArgumentException("Attempting to expose different objects under the same name '" + name + "'");
            }
            return entity;
        }

        public bool TryResolve(string name, Dictionary<string, object> payload, out ChildEntity entity)
        {
            if (children.TryGetValue(name, out entity))
                return true;

            foreach (IFacet facet in facets)
            {
                object obj;
                if (facet.TryResolve(name, payload, out obj))
                {
                    entity = Expose(name, obj);
                    return true;
                }
            }

            entity = null;
            return false;
        }

        public void ProcessIncomingUpdate(IDictionary<string, object> payload, PayloadDelegate reply)
        {
            // properties
            var properties = payload.Where(e => !e.Key.StartsWith("#") && !e.Key.StartsWith("!")).ToDictionary(e => e.Key, e => e.Value);
            foreach (IFacet facet in facets)
                if (properties.Count > 0)
                    // properties can be mutated by this call
                    facet.Set(properties);

            // the remaining property keys haven't been recognized by any facets
            if (properties.Count > 0)
                throw new PayloadException("Incoming payload contains invalid keys: " + string.Join(", ", properties.Keys));

            // children
            foreach (var entry in payload.Where(e => e.Key.StartsWith("#")))
            {
                string name = entry.Key.Substring(1);
                var childPayload = (Dictionary<string, object>) entry.Value;

                ChildEntity child;
                // childPayload can be mutated by this call
                if (!TryResolve(name, childPayload, out child))
                    throw new PayloadException("Cannot resolve child named: " + name);

                // childPayload can and likely will be mutated by this call
                child.ProcessIncomingUpdate(childPayload, reply);
            }

            // methods
            foreach (var entry in payload.Where(e => e.Key.StartsWith("!")))
            {
                string name = entry.Key.Substring(1);
                object[] args = ((IList<object>) entry.Value).ToArray();
                foreach (var facet in facets)
                {
                    if (facet.TryInvoke(name, args, reply))
                        break;
                }
            }
        }

        public abstract void SendUpdate(Dictionary<string, object> payload);
    }

    // All entites created via Expose or Resolve calls are ChildEntities
    // (that is, all entities except for the root one).
    public class ChildEntity : Entity
    {
        public readonly Entity parent;
        public readonly string name;
        public readonly object obj;

        public ChildEntity(Entity parent, string name, object obj)
        {
            this.parent = parent;
            this.name   = name;
            this.obj    = obj;

            AddNativeObject(obj);
        }

        public override RootEntity Root
        {
            get { return parent.Root; }
        }

        public override string Path
        {
            get { return parent.PathPrefix + "#" + name; }
        }

        public override string PathPrefix
        {
            get { return parent.PathPrefix + "#" + name + " "; }
        }

        public override void SendUpdate(Dictionary<string, object> payload)
        {
            parent.SendUpdate(new Dictionary<string, object> { { "#" + name, payload } });
        }
    }

    // The root entity does not correspond to any native objects, and is used to gain access to the real exposed objects.
    // In addition, the root entity holds the data common for the entire hierarchy.
    public class RootEntity : Entity
    {
        internal readonly List<FacetRegistration> facetRegistrations = new List<FacetRegistration>();

        // unused so far
        public event PayloadDelegate OutgoingUpdate;

        public RootEntity() { }

        public override RootEntity Root
        {
            get { return this; }
        }

        public override string Path
        {
            get { return "(root)"; }
        }

        public override string PathPrefix
        {
            get { return ""; }
        }

        public void Register(Type objType, Type facetType)
        {
            facetRegistrations.Add(new FacetRegistration(objType, facetType));
        }

        public override void SendUpdate(Dictionary<string, object> payload)
        {
            if (OutgoingUpdate != null)
                OutgoingUpdate(payload);
        }
    }

    public class FacetRegistration
    {
        private readonly Type objType;
        private readonly Type facetType;

        public FacetRegistration(Type objType, Type facetType)
        {
            this.objType = objType;
            this.facetType = facetType;
        }

        public bool TryCreate(ChildEntity obj, out IFacet facet)
        {
            if (objType.IsAssignableFrom(obj.obj.GetType()))
            {
                facet = (IFacet)Activator.CreateInstance(facetType, obj, obj.obj);
                return true;
            }
            else
            {
                facet = null;
                return false;
            }
        }
    }
}
