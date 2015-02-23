
String types
==============

- [string](#string), This is implemented as character array in generated C code.
- [xtring](#xtring), This is a *class* containing a string reference. The *class* and the *string* data may or may not reside in consequtive memory.
- [extring](#extring), This is a *struct* containing a string reference. The context contains the memory of the variable to give it better integrity. It may also reside in stack on the contrary of xtring. It is lightweight implementation of xtring.

string
=======

string contains array of characters in consecutive memory. They are the plain character array in the generated C code.

#### Printing a string

Printing a string is simple. The print() method prints the string to the standard output. Note, that in the formatted output the string needs to be **zero terminated**.

```vala
string x = "hello"; // This is null turminated static string.
print("%s\n", x); // This prints "hello\n" in the screen.
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

#### Declaration and definition

The strings can be referenced in the code when it is allocated in heap or in program stack. It is possible to avoid memory copy by just referencing the heap string. For example, if there is a string literal `hello`, it is possible to define it like the following.

```vala
xtring hello = new xtring.copy_static_string("hello");
```

This will allocate a memory in heap for *xtring* structure as well as the "hello" string literal. It is possible to do either [deep_copy](http://en.wikipedia.org/wiki/Deep_copy#Deep_copy) or [shallow_copy](http://en.wikipedia.org/wiki/Deep_copy#Shallow_copy) or [copy_on_demand](http://en.wikipedia.org/wiki/Deep_copy#Lazy_copy) of this string.

extring
=========

#### Declaration and definition

Again it is possible to allocate memory in stack.

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
extring hello = extring.stack(128);
hello.concat_string("hello");
```

It is possible to know the memory size by `size()` method and string length by `length()` method. So the memory left over is `hello.size() - hello.length()`.



#### Comparison

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
trim | `x[ i ] = '\0';` | NA | `x. fly() . trim_to_length( i );` | `x. trim_to_length( i );`
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



#### Copying

Now suppose you want to pass by value and set the extring parameter to a method. You can do that like the following.

```vala
public void getAs(extring*content) {
	content.rebuild_and_copy_on_demand(&cache);
}
```

#### Sandbox
You can copy a string into stack for processing.

```vala
extring sandbox = extring.stack_copy_extring(immutablextring);
```

#### Heap memory
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

#### Traversing

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

#### Factory

You can also create factory for _xstring_ and build them.

```vala
extring src = extring.set_static_string("I shall be in the factory memory");
Factory<xtring> myTxtFactory = Factory<xtring>.for_type();
xtring x = xtring.factory_build_and_copy_deep(&myTxtFactory,&src);
```

You can even build it in searchable factory.

```vala
SearchableFactory<SearchableString> myTxtFactory = SearchableFactory<SearchableString>.for_type(); // searcable factory
SearchableString x = SearchableString.factory_build_and_copy_deep(&myTxtFactory,&src);
```

Note that the _xtring_ built in the factory will not be available when the factory is destroyed. So be sure to scope them in the boundary of factory existance(do not let others internalize them).

#### Error generated by returning extring in a method

Suppose you have an instance variable of type extring. If you return this in a method, then it will be freed in the caller function resulting in double free. You need to take special care about this.

TODO: write more about copying and referencing strings.

Common mistakes
===============

#### extring x = extring() will not allocate any memory

There is a common mistake to think that the extring() constructor may allocate intelligent things to allocate memory. And with that wrong concept, it is wrong to concat character to `x`.

```vala
extring x = extring(); // in this definition x.size() = 0
x.concat_string("great"); // this will not work as the x does not have memory
```




