OPPFactory
==========
OPPFactory is the foundation of object pool. It contains allocation methods. The objects are allocated from pool. And the objects are garbage collected. 

#### Creating OPPFactory

OPPFactory can be of a given Class. It allocates chunks of memory. Each chunk contains a pool of object of the given class.

```vala
var pool = OPPFactory<xtring>.for_type(); // It creates pool for xtring objects.
```

It is possible to specify the number of objects in each pool.

```vala
var pool = OPPFactory<xtring>.for_type_full(32, (uint)sizeof(xtring)+64); // It contains 32 strings in one chunk each containing at least 32 characters.
```

#### Creating objects

An object can be allocated by alloc_full() method.

```vala
xtring x = pool.alloc_full();
```

#### Traversing

```vala
foreach(xtring x in pool)
	print(" - %s", x.fly().to_string());
```

Please refer to [OPPFactory](../example/collection_example/oppfactory_example/vsrc/OPPFactoryExample.vala) to get the example source.

SearchableOPPFactory
====================

SearchableOPPFactory contains searchable objects. These objects are associated with a tree and they can be searched from the pool.

// TODO show example



