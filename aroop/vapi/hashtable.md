HashTable<G,K>
==============

Hashtable lets the code to arrange objects in pairs. It is a list of pairs.

#### Createing HashTable

Hashtables can be created using hash function and equality compare function callbacks.

```vala
HashTable<xtring,xtring> ht = HashTable<xtring,xtring>(xtring.hCb, xtring.eCb);
```

Note the hash function and equality comparison function work on the type of first generic argument. And the second generic arguments is the type of object it maps to.

#### Accessing elements

The hashtable can access and set elements by the type of first generic argument.

```vala
xtring key = new xtring.set_static_string("fruit:1");
xtring value = new xtring.set_static_string("Mango");

HashTable<xtring,xtring> ht = HashTable<xtring,xtring>(xtring.hCb, xtring.eCb);
ht.set(key, value); // set value "Mango" in space of key "fruit:1"
var ft = ht.get(key); // returns "Mango"
```

#### HashTable is a OPPList

Note that internaly the hashtable is managed by AroopPointer and it is possible to get the pointer using the `OPPList` methods.

```vala
foreach(AroopPointer<xtring> pt3 in mymap) {
	unowned xtring x3 = pt3.getUnowned();
	print("%s\n", x3.fly().to_string()); // prints Mango
}
```

AroopHashTablePointer is extended from AroopPointer, it allows access to the key.

```vala
foreach(AroopHashTablePointer<xtring,xtring> pt3 in mymap) {
	unowned xtring key4 = pt3.key();
	unowned xtring x4 = pt3.getUnowned();
	print("%s=%s\n", key4.fly().to_string(), x4.fly().to_string()); // fruit:1=Mango
}
```

#### Example

Please refer to [HashTableExample.vala](../example/collection_example/hashtable_example/vsrc/HashTableExample.vala) to get the example source.

