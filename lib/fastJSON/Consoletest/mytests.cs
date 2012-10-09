using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Reflection;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using fastJSON;


namespace Tests
{
	#region

	[Serializable()]
	public class baseclass
	{
		public string Name { get; set; }
		public string Code { get; set; }
	}

	[Serializable()]
	public class class1 : baseclass
	{
		public class1() { }
		public class1(string name, string code, Guid g)
		{
			Name = name;
			Code = code;
			guid = g;
		}
		public Guid guid { get; set; }
	}

	[Serializable()]
	public class class2 : baseclass
	{
		public class2() { }
		public class2(string name, string code, string desc)
		{
			Name = name;
			Code = code;
			description = desc;
		}
		public string description { get; set; }
	}

	[Serializable()]
	public class colclass
	{
		public colclass()
		{
			items = new List<baseclass>();
			date = DateTime.Now;
			Ppp = @"
            AJKLjaskljLA
       ahjksjkAHJKS
       AJKHSKJhaksjhAHSJKa
       AJKSHajkhsjkHKSJKash
       ASJKhasjkKASJKahsjk
            ";
			gggg = Guid.NewGuid();
			//hash = new Hashtable();
			isNew = true;
			done= true;
		}
		public bool done { get; set; }
		public DateTime date {get; set;}
		//public DataSet ds { get; set; }
		public string Ppp { get; set; }
		public List<baseclass> items { get; set; }
		public Guid gggg {get; set;}
		public decimal? dec {get; set;}
		public bool isNew { get; set; }
		//public Hashtable hash { get; set; }

	}
	#endregion

	[TestFixture]
	public class mytests : TestFixtureBase
	{
		public mytests()
		{
			ds = CreateDataset();
			Console.WriteLine("count = " + count);
		}
		static DataSet ds;
		int count = 1000;
		
		[Test]
		public void a_new_serializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			string jsonText = null;
			c= CreateObject();
			for (int i = 0; i < count; i++)
			{
				jsonText = JSON.Instance.ToJSON(c);
			}
			//colclass deserializedStore = ServiceStack.Text.JsonSerializer.DeserializeFromString<colclass>(jsonText);
			//Console.WriteLine("Size = " + jsonText.Length);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		[Test]
		public void b_new_deserializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			string jsonText = null;
			c= CreateObject();
			object o ;
			jsonText = JSON.Instance.ToJSON(c);
			for (int i = 0; i < count; i++)
			{
				o=JSON.Instance.ToObject(jsonText);
			}
			//colclass deserializedStore = ServiceStack.Text.JsonSerializer.DeserializeFromString<colclass>(jsonText);
			//Console.WriteLine("Size = " + jsonText.Length);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		[Test]
		public void a_Stack_Serializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			string jsonText = null;
			c= CreateObject();
			for (int i = 0; i < count; i++)
			{
				jsonText = ServiceStack.Text.JsonSerializer.SerializeToString(c);
			}
			//colclass deserializedStore = ServiceStack.Text.JsonSerializer.DeserializeFromString<colclass>(jsonText);
			//Console.WriteLine("Size = " + jsonText.Length);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		
		[Test]
		public void a_Lit_Serializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			string jsonText = null;
			c= CreateObject();
			for (int i = 0; i < count; i++)
			{
				jsonText = JSON.Instance.ToJSON(c);
			}
			//object deserializedStore = JsonMapper.ToObject(jsonText);
			//Console.WriteLine("Size = " + jsonText.Length);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}

		[Test]
		public void a_nJson_Serializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			JsonSerializerSettings s = null;
			string jsonText = null;
			s = new JsonSerializerSettings();
			s.TypeNameHandling = TypeNameHandling.All;
			c= CreateObject();
			
			for (int i = 0; i < count; i++)
			{
				jsonText = JsonConvert.SerializeObject(c, Formatting.Indented, s);
			}
			//Console.WriteLine("Size = " + jsonText.Length);
			//colclass deserializedStore = (colclass)JsonConvert.DeserializeObject(jsonText, typeof(colclass), s);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}


		[Test]
		public void b_nJson_DeSerializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			colclass deserializedStore = null;
			JsonSerializerSettings s = null;
			string jsonText = null;
			c= CreateObject();
			s = new JsonSerializerSettings();
			s.TypeNameHandling = TypeNameHandling.All;
			jsonText = JsonConvert.SerializeObject(c, Formatting.Indented, s);
			for (int i = 0; i < count; i++)
			{
				deserializedStore = (colclass)JsonConvert.DeserializeObject(jsonText, typeof(colclass), s);
			}
			//WriteObject(deserializedStore);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		[Test]
		public void b_bin_DeSerializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			colclass deserializedStore= null;
			c= CreateObject();
			BinaryFormatter bf = new BinaryFormatter();
			MemoryStream ms = new MemoryStream();
			bf.Serialize(ms,c);
			
			for (int i = 0; i < count; i++)
			{
				ms.Seek(0L,SeekOrigin.Begin);
				deserializedStore =	(colclass)bf.Deserialize(ms);
			}
			//WriteObject(deserializedStore);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		[Test]
		public void a_bin_Serializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			c= CreateObject();
			BinaryFormatter bf = new BinaryFormatter();
			MemoryStream ms = new MemoryStream();
			for (int i = 0; i < count; i++)
			{
				ms=new MemoryStream();
				bf.Serialize(ms,c);
			}
			//WriteObject(deserializedStore);
			//Console.WriteLine("Size = " + ms.Length);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		[Test]
		public void b_Stack_DeSerializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			colclass deserializedStore= null;
			string jsonText = null;
			c= CreateObject();
			jsonText = ServiceStack.Text.JsonSerializer.SerializeToString(c);
			for (int i = 0; i < count; i++)
			{
				deserializedStore =	ServiceStack.Text.JsonSerializer.DeserializeFromString<colclass>(jsonText);
			}
			//WriteObject(deserializedStore);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		public static colclass CreateObject()
		{
			var			c = new colclass();
			//c.ppp = "hello";
			//c.ds = ds;
			//c.hash.Add("pppp",new class1("1", "1", Guid.NewGuid()));
			//c.hash.Add(22,new class2("2", "2", "desc1"));
			c.done=true;
			c.items.Add(new class1("1", "1", Guid.NewGuid()));
			c.items.Add(new class2("2", "2", "desc1"));
			c.items.Add(new class1("3", "3", Guid.NewGuid()));
			c.items.Add(new class2("4", "4", "desc2"));
			return c;
		}
		
		[Test]
		public void b_Lit_DeSerializer()
		{
			DateTime st = DateTime.Now;
			colclass c;
			colclass deserializedStore=null;
			string jsonText = null;
			c= CreateObject();
			jsonText = JSON.Instance.ToJSON(c);
			for (int i = 0; i < count; i++)
			{
				deserializedStore =	(colclass)JSON.Instance.ToObject(jsonText);
			}
			//WriteObject(deserializedStore);
			Console.WriteLine("time ms = " + DateTime.Now.Subtract(st).TotalMilliseconds);
		}
		
		private void WriteObject(colclass obj)
		{
			foreach(object c in obj.items)
				;//Console.WriteLine(""+c.GetType());
		}
		
		public static DataSet CreateDataset()
		{
			DataSet ds = new DataSet();
			for (int j = 1; j < 3; j++)
			{
				DataTable dt = new DataTable();
				dt.TableName = "Table" + j;
				dt.Columns.Add("col1", typeof(int));
				dt.Columns.Add("col2", typeof(string));
				dt.Columns.Add("col3", typeof(Guid));
				dt.Columns.Add("col4", typeof(string));
				dt.Columns.Add("col5", typeof(bool));
				dt.Columns.Add("col6", typeof(string));
				dt.Columns.Add("col7", typeof(string));
				ds.Tables.Add(dt);
				Random rrr = new Random();
				for (int i = 0; i < 100; i++)
				{
					DataRow dr = dt.NewRow();
					dr[0] = rrr.Next(int.MaxValue);
					dr[1] = "" + rrr.Next(int.MaxValue);
					dr[2] = Guid.NewGuid();
					dr[3] = "" + rrr.Next(int.MaxValue);
					dr[4] = true;
					dr[5] = "" + rrr.Next(int.MaxValue);
					dr[6] = "" + rrr.Next(int.MaxValue);

					dt.Rows.Add(dr);
				}
			}
			return ds;
		}
	}
}
