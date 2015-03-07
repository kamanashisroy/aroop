ArrayList<G>
===========

ArrayList adds set() and get() method over normal SearchableOPPList. It hides the AroopPointer and the elements can be accessed using `[]` operator. Unlike SearchableOPPList it does not use token to retrieve object but the hash. And the hash value is set as array index while adding into the list. Thus getting and setting of array is tree operation(while getByToken() is not and thus faster).

#### creating ArrayList

Creating arraylist is as simple as calling the default constructor.

```vala
ArrayList<xtring> array = ArrayList<xtring>();
```

It is possible to specify the number of AroopPointers containing in each pool.

```vala
ArrayList<xtring> array = ArrayList<xtring>(32); // allocates memory chunk to contain upto 32 AroopPinters
```

#### Using the array

The `[]` operator is used to set and get array values.

```vala
xtring x = new xtring.set_static_string("Have a nice day.");
array[0] = x; // It adds xtring containing "Have a nice day" into the array
```

Note that it inherits all the methods from SearchableOPPList and it can be searched over index and it can also get the token of the ArrayPointer.

Please refer to [ArrayListExample.vala](../example/collection_example/arraylist_example/vsrc/ArrayListExample.vala) to get the example source.

