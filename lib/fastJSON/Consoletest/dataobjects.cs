using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;

namespace consoletest
{

	#region [   data objects   ]

	public class baseclass
	{
		public string Name { get; set; }
		public string Code { get; set; }
	}

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
	
	public enum Gender
	{
		Male,
		Female
	}

	public class colclass
	{
		public colclass()
		{
			items = new List<baseclass>();
			date = DateTime.Now;
			multilineString = @"
            AJKLjaskljLA
       ahjksjkAHJKS سلام فارسی
       AJKHSKJhaksjhAHSJKa
       AJKSHajkhsjkHKSJKash
       ASJKhasjkKASJKahsjk
            ";
			isNew = true;
			booleanValue = true;
			ordinaryDouble = 0.001;
			gender = Gender.Female;
			intarray = new int[5] {1,2,3,4,5};
		}
		public bool booleanValue { get; set; }
		public DateTime date {get; set;}
		public string multilineString { get; set; }
		public List<baseclass> items { get; set; }
		public decimal ordinaryDecimal {get; set;}
		public double ordinaryDouble { get; set ;}
		public bool isNew { get; set; }
		public string laststring { get; set; }
		public Gender gender { get; set; }
		
		public DataSet dataset { get; set; }
		public Dictionary<string,baseclass> stringDictionary { get; set; }
		public Dictionary<baseclass,baseclass> objectDictionary { get; set; }
		public Dictionary<int,baseclass> intDictionary { get; set; }
		public Guid? nullableGuid {get; set;}
		public decimal? nullableDecimal { get; set; }
		public double? nullableDouble { get; set; }
		public Hashtable hash { get; set; }
		public baseclass[] arrayType { get; set; }
		public byte[] bytes { get; set; }
		public int[] intarray { get; set; }
		
	}
	#endregion

}
