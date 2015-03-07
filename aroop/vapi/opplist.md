OPPList
========

The aroop core library is based on object pooling. The List contains collection of objects. By definition list is contains sequential objects. OPPList uses pool to keep the **reference** of objects. The references are called *[AroopPointers](arooppointer.md)*. It uses *tokens* to identify contained objects. The *tokens* makes the objects sequential in some sense.

#### creating OPPList

Creating opplist is as simple as calling the default constructor.

```vala
OPPList<xtring> mylist = OPPList<xtring>(); // creates a pooled list
```

It is possible to specify the number of AroopPointers containing in each pool.

```vala
OPPList<xtring> mylist = OPPList<xtring>(32); // allocates memory chunk to contain upto 32 AroopPinters
```

Also, a list can be marked by any of the [factory_flags](factory.md#factory_flags).

```vala
OPPList<xtring> mylist = OPPList<xtring>(32, factory_flags.HAS_LOCK); // allocates memory chunk to contain upto 32 AroopPinters and it uses locking to allow different thread to operate on this list in mutual exclusion.
```

#### Adding objects

The `add()` method adds an object to the list.

```vala
xtring x = new xtring.set_static_string("Have a nice day.");
mylist.add(x); // It adds xtring containing "Have a nice day" into the list
```

It is possible to get underlying AroopPointer object created by using `add_pointer()`. It can also be used to set appropriate hash and flag to the created pointer.

```vala
xtring x = new xtring.set_static_string("Have a nice day.");
AroopPointer<xtring> pt = mylist.add_pointer(x, x.getStringHash()); // It adds xtring containing "Have a nice day" into the list and sets hash
```

#### Getting

Token is used to retrieve an item from the list. Token is available only when the list is marked with flag `EXTENDED`.

```vala
OPPList<xtring> mylist = OPPList<xtring>(32, factory_flags.EXTENDED); // allocates memory chunk to contain upto 32 AroopPinters and it uses locking to allow different thread to operate on this list in mutual exclusion.

xtring x = new xtring.set_static_string("Have a nice day."); // create a xtring
AroopPointer<xtring> pt = mylist.add_pointer(x); // It adds xtring containing "Have a nice day" into the list
int token = pt.get_token(); // get the token of the pointer

AroopPointer<xtring> pt2 = mylist.get_by_token(token); // retrieve the AroopPointer from the list
xtring x2 = pt2.get();

print("x and x2 are %s.\n", x2 == x ? "equal" : "not equal"); // prints "equal"

```

#### Iteration

It is possible to iterate OPPList using `foreach` statement.

```vala
foreach(AroopPointer<xtring> pt3 in mylist) {
	unowned xtring x3 = pt3.getUnowned();
	print("%s\n", x3.fly().to_string());
}
```

#### Iteration revisited

TODO show how the iterator_hacked() do hash and flag based iteration.

#### Example source

Please refer to [OPPListExample](../example/collection_example/opplist_example/vsrc/OPPListExample.vala) to get the example source.


