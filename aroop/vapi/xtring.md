
String types
==============

- [string](#string), This is implemented as character array in generated C code.
	- [Creation](#creating-string)
	- [Mutability](#string-mutability)
	- [Printing](#printing-string)
	- [Common mistakes](#common-mistakes-with-string)
	- [Generated code](#generated-code-for-string)
	- [Convertion to primitive type](#string-to-primitive-type)
- [xtring](#xtring), This is a *class* containing a string reference. The *class* and the *string* data may or may not reside in consequtive memory. 
	- [Creation](#creating-xtring)
	- [Flyweight pattern](#flyweight-pattern)
	- [Mutability](#xtring-mutability)
	- [Printing](#printing-xtring)
	- [Common mistakes](#common-mistakes-with-xtring)
	- [Generated code](#generated-code-for-xtring)
	- [Convertion to primitive type](#xtring-to-primitive-type)
	- [Factory for xtring](#factory-for-xtring)
- [extring](#extring), This is a *struct* containing a string reference. The context contains the memory of the variable to give it better integrity. It may also reside in stack on the contrary of xtring. It is lightweight implementation of xtring.
	- [Creation](#creating-extring)
	- [Mutability](#extring-mutability)
	- [Printing](#printing-extring)
	- [Returning extring](#returning-extring)
	- [Sandboxing](#sandboxing)
	- [Heap memory for extring](#heap-memory-for-extring)
	- [Traversing extring](#traversing-extring)
	- [Convertion to primitive type](#extring-to-primitive-types)
	- [Convertion from primitive type and formatting](#primitive-types-to-extring)
	- [Equality](#extring-equality)
	- [Concatanation](#extring-concatanation)
	- [Substring](#extring-substring)
	- [Generated code](#generated-code-for-extring)
	- [Common mistakes](#common-mistakes-with-extring)

There is a [comparison table](#comparison-table) for better understanding of string types.

string
=======

*string* contains array of characters in consecutive memory. They are the plain character array in the generated C code.

#### Creating string

The string declaration is as simple as follows.

```vala
string x; // here x is reference variable
```

Defining the string is done by string literal.

```vala
x = "hello";
```

Or the string creation can be done in one statement.

```vala
string x = "hello";
```

As in vala one can use `var` keyword.

```vala
var x = "world"; // here y is string variable
```

It is possible to get string from other methods. For example, it is possible to derive `string` from `extring` by calling the `to_string()` method.

```vala
extring x = extring.set_static_string("hello");
var y = x.to_string(); // here y is string variable and it contains "hello"
```

#### String Mutability 

The string class contains immutable character array. The following code generates an immutable string.

```vala
string x = "hello"; // the content of x is immutable
```

The above code does not allocate any memory from heap. The memory is referenced from stack. Modifying the characters may result in program crash.

#### Printing string

Printing a string is simple. The print() method prints the string to the standard output. Note, that in the formatted output the string needs to be **zero terminated**.

```vala
string x = "hello"; // This is null turminated immutable string.
print("%s\n", x); // This prints "hello\n" on the screen.
```

#### Common mistakes with string

The following commands are not allowed.

```vala
string x = new string();
string y = new string("hello");
```

#### Generated code for string

```vala
string x = "hello";
```

The code above generates the following C code.

```vala
char*x = "hello";
```

#### String to primitive types

The following code converts string into integer.

```vala
string x = "10";
int i = x.to_int();
```

xtring
=======

Aroop contains special support for strings. While `string` class is originally the character array in C output, the `xtring` contains additional information. Xtring has support for,

- Embeded/stack allocated container.
- Stack allocated string.
- Heap allocated string.
- Immutable string.
- A hash value and precalculated length value.

The `extring` is of `struct` type so it can reduce memory allocation in some cases. It supports [flyweight pattern](http://en.wikipedia.org/wiki/Flyweight_pattern) to reduce data duplication and copying. It is always possible to get _extring_ from _xtring_ calling fly() method.

#### Creating xtring

The xtring declaration is as simple as follows.

```vala
xtring x; // here x is reference variable
```

Defining the xtring is done by following constructors.

 constructor | example | allocation | size | content | mutability
-------------|---------|------------|------|---------|----------------
 `xtring( char * content, uint len = 0, aroop. Replicable? proto = null, aroop. Factory < xtring >* pool = null )` | `x = new xtring( "hello" , 5);` | `sizeof( xtring )` | 5 | `"hello"` | mutable
 `xtring. alloc( uint len = 0, aroop. Factory < xtring >* pool = null )` | `x = new xtring. alloc( 5);` | `sizeof( xtring ) + 5` | 5 | "" | mutable
 `xtring. copy_on_demand( extring * src, Factory < xtring >* pool = null )` | `x = new xtring. copy_on_demand( &other );` | `sizeof( xtring )` or `sizeof( xtring ) + other. length()` | `other. length()` | `other. to_string()` | `other. isMutable()` when referenced otherwise mutable when copied
 `xtring. copy_shallow( extring * src, Factory < xtring >* pool = null )` | `x = new xtring. copy_shallow( &other );` | `sizeof( xtring )` | `other. length()` | `other. to_string()` | `other. isMutable()`
 `xtring. copy_deep( extring * src, Factory < xtring >* pool = null )` | `x = new xtring. copy_deep( &other );` | `sizeof( xtring ) + other. length()` | `other. length()` | `other. to_string()` | mutable
 `xtring. copy_content( char* content, uint len = 0, Factory < xtring >* pool = null )` | `x = new xtring. copy_content( "hello", 5 , null );` | `sizeof( xtring ) + 5` | 5 | "hello" | mutable
 `xtring. copy_string( string content, Factory < xtring >* pool = null )` | `x = new xtring. copy_string( "hello" );` | `sizeof( xtring ) + 5` | 5 | "hello" | mutable
 `xtring. copy_static_string( string content, Factory < xtring >* pool = null )` | `x = new xtring. copy_static_string( "hello" );` | `sizeof( xtring )` | 5 | "hello" | immutable


It is possible to do either [deep_copy](http://en.wikipedia.org/wiki/Deep_copy#Deep_copy) or [shallow_copy](http://en.wikipedia.org/wiki/Deep_copy#Shallow_copy) or [copy_on_demand](http://en.wikipedia.org/wiki/Deep_copy#Lazy_copy) of this string. Here are some examples of xtring creation.

```vala
xtring x = new xtring.set_static_string("hello"); // it takes low memory . but it makes the string immutable
x = new xtring.copy_static_string("hello"); // it allocates 6 bytes of memory and copies "hello" into that, the string is mutable
string xst = "hello";
x = new xtring.copy_string(xst); // it allocates 6 bytes of memory and copies "hello" into that, it is mutable
x = new xtring.alloc(128); // it allocates 128 bytes in the heap
```

#### Flyweight pattern

It is possible to get `struct` type pointer from xtring `class` by calling `fly()` command. In this way the methods of `extring` is available for `xtring` class.

```vala
xtring x = new xtring.copy_static_string("hello");
x.fly().length(); // get the length (5)
```

#### Xtring Mutability 

The above constructors show the ways xtring can be mutable. It is also possible to make a string mutable by calling `makeConstant()` method. A immutable string cannot be converted to immutable.

```vala
xtring x = new xtring.copy_static_string("hello"); // the content of x is mutable
x.fly().makeConstant();
x.fly().concat_string(" world"); // it will not concat the " world" because the xtring is immutable
```

#### Printing xtring

Printing xtring is done by converting it into extring and then calling `to_string()` method.

```vala
xtring x = new xtring.set_static_string("hello");
print("%s\n", x.fly().to_string()); // This prints "hello\n" on the screen.
```

#### Common mistakes with xtring

FILLME

#### Generated code for xtring

FILLME

#### Xtring to primitive types

The following code converts string into integer.

```vala
xtring x = new xtring.set_static_string("10");
int i = x.fly().to_int();
```

#### Factory for xtring

It is possible to create factory for _xstring_ and build them.

```vala
extring src = extring.set_static_string("I shall be in the factory memory");
Factory<xtring> myTxtFactory = Factory<xtring>.for_type();
xtring x = xtring.factory_build_and_copy_deep(&myTxtFactory,&src);
```

it can also be in searchable factory.

```vala
SearchableFactory<SearchableString> myTxtFactory = SearchableFactory<SearchableString>.for_type(); // searcable factory
SearchableString x = SearchableString.factory_build_and_copy_deep(&myTxtFactory,&src);
```

Note that the _xtring_ built in the factory will not be available when the factory is destroyed. So it is required to scope them in the boundary of factory existance(let not others internalize them).


extring
=========

extring is of value type. Local extring variables are kept in stack memory while the extring fields are kept in the owner class memory. There is no separate heap allocation needed for empty extring structure.

#### Creating extring

It is possible to allocate memory in stack.

```vala
extring hello = extring.set_static_string("hello"); // no new keyword is needed as it is allocated in stack.
```

The above code will keep the string totally in stack memory.  The "hello" literal is only referenced but it is not copied.

The following code will create hello and allocate 128 additional bytes from stack memory.

```vala
extring hello = extring.stack(128);
```

The following code will allocate hello and copy the "hello" string into its stack space of 128 byte.

```vala
extring hello = extring.stack(128); // allocate 128 bytes in stack
hello.concat_string("hello"); // copy the string into stack memory
extring hello2 = extring.stack_copy_deep(&hello); // allocate 6 bytes in stack and copy "hello" there
```

Again the string can also be kept in heap memory.

```vala
extring hello = extring(); // empty
hello.rebuild_in_heap(128); // allocate 128 bytes in heap
hello.concat_string("hello"); // copy "hello" into heap
extring hello2 = extring.copy_deep(&hello); // allocates 6 bytes in heap and copies "hello" into heap
```

It is possible to know the memory size by `size()` method and string length by `length()` method. So the memory left over is `hello.size() - hello.length()`.

#### Extring Mutability 

The above constructors show the ways extring can be mutable. It is also possible to make a string mutable by calling `makeConstant()` method. A immutable string cannot be converted to immutable.

```vala
extring x = extring.copy_static_string("hello"); // the content of x is mutable
x.makeConstant();
x.concat_string(" world"); // it will not concat the " world" because the extring is immutable
```

#### Printing extring

Printing extring is done by converting it into string by calling `to_string()` method.

```vala
extring x = extring.set_static_string("hello");
print("%s\n", x.to_string()); // This prints "hello\n" on the screen.
```

#### Returning extring

The `getAs(extring*output)` is typical way to get string from a class. For example the following *A class* defines *getAs* to get it's name.

```vala
public class A : Replicable {
	extring a;
	public A() {
		a = extring.set_static_string("A");
	}
	public void getAs(extring*content) {
		content.rebuild_and_copy_on_demand(&a);
	}
}
```

#### Sandboxing

It is possible to copy a string into stack for processing.

```vala
extring sandbox = extring.stack_copy_extring(immutablextring); // mutable
```

#### Heap memory for extring
Heap memory is obvious in some cases. The `extring.rebuild_in_heap(int size)` can be used to allocate memory space in any string type.

```vala
extring heap = extring();
heap.rebuild_in_heap(128);
heap.concat_string("I shall be in the heap memory");
```

Heap memory can be used if the string is set as output. For example, the following method adds suffix to a given string.

```vala
void addSuffix(extring*input, extring*suffix, extring*output) {
	output.rebuild_in_heap(input.length()+suffix.length()+1);
	output.concat(input);
	output.concat(suffix);
}
```

#### Traversing extring

Each byte of the xtring can be accessed as follows,

```vala
extring content = extring.stack(128); // allocate 128 bytes in stack memory
content.concat_string("hello\nworld\n"); // copy "hello\nworld\n"
extring line = extring.stack(content.length()); // allocate memory space for each line
int i = 0;
for(i = 0; i < content.length(); i++) { // traverse all the elements starting from 0 to content.length()
	uchar ch = content.char_at(i); // get the character at index i
	if(ch == '\n') { // check if it is line break
		line.zero_terminate(); // null terminate the string (as in C strings are null terminated, so printing the string needs to be null terminated)
		print("%s\n", line.to_string()); // show the line
		line.truncate(); // it sets the line length to 0, so that next line can be added here
		continue;
	}
	line.concat_char(ch); // concat ch to the line 
}
```

#### Generated code for extring

FILLME

#### Extring to primitive types

The following code converts string into integer.

```vala
extring x = extring.set_static_string("10");
int i = x.to_int();
```


#### Primitive types to extring

The following code formats different types into extring.

```vala
extring buffer = extring.stack(128);
buffer.printf("number:%d, long:%l, character:%c", 4, 4L, 'a');
// buffer now contains "number:4, long:4, character:a" 
```

#### Extring equality

The following table shows the method available for extring comparison.

  method | example | returns | case sensitivity
---------|---------|--------|------------------
 `bool equals( extring * other )` | `x. equals( &y )` | boolean | sensitive
 `bool iequals( extring * other )` | `x. iequals( &y )` | boolean | insensitive
 `bool equals_string( string other )` | `x. equals_string( "hello" )` | boolean | sensitive
 `bool equals_static_string( string other )` | `x. equals_static_string( "hello" )` | boolean | sensitive
 `int cmp( extring * other )` | `x.cmp( &y ) == 0` | integer | sensitive

Here are some examples of string comparisons.

```vala

string nice = "nice";
extring x1 = extring.set_string(nice); // contains immutable "nice"
extring x2 = extring.set_string("nice"); // contains immutable "nice"
xtring x3 = new xtring.set_string(nice); // contains immutable "nice"
xtring x4 = new xtring.copy_deep(x3); // contains mutable "nice"

// the variables are different in value
(x1 == nice); // false
(x2 == nice); // false
(x3 == nice); // false
(x1 == x2); // false
(x1 == x3); // false
(x1 == x4); // false

// The to_string() returns the underlying source string
(x1.to_string() == nice); // true
(x1.to_string() == x2.to_string()); // Depends on the compiler, if interned then true otherwise false
(x1.to_string() == x3.fly().to_string()); // true
(x1.to_string() == x4.fly().to_string()); // false

// equals function checks the hashcode equality or every byte if the lengths are equal
(x1.get_hash() == x2.get_hash()); // true
(x1.equals(&x2)); // true
(x1.get_hash() == x3.fly().get_hash()); // true
(x1.equals(x3)); // true
(x1.get_hash() == x4.fly().get_hash()); // true
(x1.equals(x4)); // true
x.equals_static_string("nice"); // true

// case sensitive matching
extring xcap = extring.set_static_string("Nice");
x.iequals(&xcap); // true

// compare function is 0 when two strings are equal

x1.cmp(&x2); // 0

```

#### Extring concatanation

Concatanation into mutable extring is done by calling one of `concat(extring*other)` or `concat_string(string*other)` and `concat_char(uchar c)` methods.

```vala
string hello = "hello"; // immutable string

// define mutable extring
extring x = extring.stack(128);

// concat string containing "hello"
x.concat_string(hello); // now it contains mutable "hello"

// concat character
x.concat_char(' ');

extring world = extring.set_static_string("world"); // this is immutable

// concat extring
x.concat(&world); // now it contains mutable "hello world"

xtring y = new xtring.copy_static_string(" from xtring .."); // this is xtring object

// concat xtring object
x.fly().concat(y); // it contains "hello world from xtring .."
```

Note that concatanation may happen if there is enough space for concatanation and if the destination is mutable.

```vala
extring x = extring.set_static_string("empty"); // immutable
x.concat_string(" cannot concat"); // this will not work, it only contains "empty"

extring x = extring.stack(3); // allocate 3 bytes in heap
x.concat_string("my content"); // after this x contains "my "
```

#### Extring substring

There is no method named `substring()`. But it is possible to do substring using given methods.

```vala
extring x = extring.set_static_string("hello world"); // immutable
extring hello = extring.set_content(x.to_string(), 5); // contains immutable "hello"
extring world = extring.copy_shallow(&x); // contains immutable "hello world"
world.shift(6); // after this statement, world contains immutable "world"
extring hello2 = extring.copy_shallow(&x); // contains immutable "hello world"
hello2.truncate(5); // after this statement, hello2 contains immutable "hello"
xtring hello3 = new xtring.copy_shallow(&x); // immutable xtring object
hello3.fly().truncate(5); // after this statement, hello3 contains immutable "hello"
```

#### Common mistakes

Suppose you have an instance variable of type extring. If you return this in a method, then it will be freed in the caller function resulting in double free. You need to take special care about this.

TODO: write more about copying and referencing strings.


#### extring x = extring() will not allocate any memory

There is a common mistake to think that the extring() constructor may allocate intelligent things to allocate memory. And with that wrong concept, it is wrong to concat character to `x`.

```vala
extring x = extring(); // in this definition x.capacity() = 0
x.concat_string("great"); // this will not work as the x does not have memory
```

Comparison table
=================

The table below shows the different aspects and comparisons among string, xtring and extring.


 criteria | char* (C) | string | xtring | extring
----------|-------------|--------|--------|----------
type | pointer | class | class(reference counted) | struct(no reference counter)
Declaring | `char*x;` | `string x;` | `xtring x;` | `extring x;`
x is | pointer | reference | reference | value 
Defining | `x = "hello";` | `x = "hello";` | `x = new xtring. set_static_string( "hello" );` | `x = extring. set_static_string( "hello" );`
Above def has | no allocation | no allocation | sizeof( xtring ) bytes | no allocation
"hello" is | immutable | immutable | immutable | immutable
Defining2 | `x = "hello";` | `x = "hello";` | `x = new xtring. copy_static_string( "hello" );` | `x = extring. copy_static_string( "hello" );`
Above def has | no allocation | no allocation | sizeof( xtring ) + 6 bytes | 6 bytes
x is | immutable | immutable | mutable | mutable
object memory | NA | NA | heap | stack and heap
getting string length | `strlen(x);` | `x.len();` | `x.fly().length();` | `x.length();`
Above length is calculated | in each call | in each call | only once | only once
printing | `printf( "%s", x);` | `print( "%s", x);` | `print( "%s", x.fly(). to_string() );` |  `print( "%s", x. to_string() );` 
stack allocation | `x = alloca(32);` | NA | NA | `extring x = extring. stack ( 32 );`
heap allocation | `x = malloc(32);` | NA | NA | `extring. rebuild_in_heap ( 32 );`
duplicate | `char* y = strdup(x);` | NA | `xtring y = new xtring. copy_deep( x )` | `extring y = extring. copy_deep ( &x );`
| | | `xtring y = new xtring. copy_shallow( x )` | `extring y = extring. copy_shallow ( &x );` 
| | | `xtring y = new xtring. copy_on_demand( x )` | `extring y = extring. copy_on_demand ( &x );`
| | | | `extring y = extring. stack_copy_deep ( &x );` 
data memory | heap/stack | heap/stack | heap/stack | heap/stack
concat | `strcat( dest, x );` | NA | `y. fly() . concat( x );` | `y. concat( &x );`
concat string | `strcat( dest, "hello" );` | NA | `y. fly() . concat_string( "hello" );` | `y. concat_string( "hello" );`
access character | `x[ i ];` | NA | `x. fly() . char_at( i );` | `x. char_at( i );`
set character | `x[ i ] = 'h';` | NA | `x. fly() . set_char_at( i , 'h' );` | `x. set_char_char( i , 'h' );`
add character | `x[ len ] = 'h';` | NA | `x. fly() . concat_char( 'h' );` | `x. concat_char( 'h' );`
null terminate | `x[ len ] = '\0';` | NA | `x. fly() . zero_terminate( );` | `x. zero_terminate( );`
trim | `x[ i ] = '\0';` | NA | `x. fly() . truncate( i );` | `x. truncate( i );`
shift | `x++;` | NA | `x. fly() . shift( 1 );` | `x. shift( 1 );`
string tokenizer | `char* token = strtok_r( x, delim, &handle )` | NA | `extring token = extring(); x. fly() . shift_token( delim, &token );` | `x. shift_token( delim, &token );`
free | `free(x);` | NA (garbage collected) | NA (garbage collected) | `y. destroy(); /* optional */`
hash | NA | NA | `x. fly( ). getStringHash( );` | `x. getStringHash( );`
equality | `strcmp( x , y ) == 0;` | NA | `x. fly( ). equals( y );` | `x. equals( y );`
equality with string | `strcmp( x, "hello" ) == 0;` | NA | `x. fly( ). equals_string( "hello" );` | `x. equals_string( "hello" );`
compare | `strcmp( x , y );` | NA | `x. fly( ). cmp( y );` | `x. cmp( y );`
check if it contains character  | `strchr( x , 'h' ) != NULL;` | NA | `x. fly( ). contains_char( y );` | `x. contains_char( y );`
format | `sprintf( x , "%d" , 1 );` | NA | `x. fly( ). printf( "%d" ,  1 );` | `x. printf( "%d" , 1 );`
int value | `atoi( x );` | NA | `x. fly( ). to_int( );` | `x. to_int( );`



