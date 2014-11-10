Aroop, the C code generator designed for writing scalable server
==========================================================

###Abstract

One of the main cause of using Aroop code generator is portability while using high level language. In fact the C programming language was popular because of universality and portability. The portability in C was achieved by compiling the universal C code into different non-portable assembly language. And Aroop is one way that portable because it can generate portable C code. Also it can use the existing C libraries by mapping them into api files.

###### Tags
Programming language, Compiler, Code generator, High level language, Object oriented language

###Summary

Aroop is a subset of Vala programming language. The Aroop compiler is a fork of Vala compiler. And the programming languages are similar as well. Both of the compilers avoid any additional ABI[1]. Both of them has the goal to use the existing C sources. The C programmers have to write a lot of boilerplate code to do simple things. These two compilers give the C programmers a way to write new code in Vala and still be able to integrate it with existing C libraries. The Vala project initially wanted to reduce boilerplate code needed for GObject based C programming. Thus it has GObject in it's core library. Aroop was developed as a compiler profile of Vala language. The idea behind Aroop is scalable server development. The Aroop does not use GObject, it uses Object-Pool-Plus library as replacement. It has memory pools and an optional Red-Black tree with memory nodes available for searching. It has object tokens. It has string type that reduces memory copy. And it has libraries to do message passing.

[1](https://wiki.gnome.org/action/recall/Projects/Vala?action=recall&rev=1)


###Features and benefits


#### Duck typing

It reduces the need of mentioning the variable type while declaration. The expression below declares a variable of type Mango in Java.

```Java
Mango x = new Mango();
```

The same thing is done below in Vala.

```Vala
var x = new Mango();
```

Clearly it reduces the number of mention of the type.

#### No header files

In C and C++ it takes time to write header files duplicating much of the code prototype. But this is not needed in Aroop. The same feature is available in Java too. Defining a Class in Vala source files is all it needs for linking.

For external linking Aroop(and Vala) automatically generates prototypes of the classes. They are listed in a file called vapi files.

#### Delegate

In some languages writing callback is either complex or needs memory allocation (for example in Java). Here it is easy to do using delegate. And it captures the required variables in the scope(it is not needed to specify them explicitly as in C++).

#### Single lambda access operator

It does not complicate things using both `->` and `.` operators as in C. It uses only `.` operator. This reduces time to refactor the code. 

#### Nullable and non-nullable variables

It can be suggested if a variable is nullable. Non-nullable variable reduces the need to be checked for being null. It uses `?` operator for that.

#### Locally scoped functions and classes

It has ways to hide the blocks of code and structures inside a package. It uses 'internal', 'private' and 'protected' access modifiers for this purpose. This helps to modify them later without worrying about how they are used outside(because they do not live outside) of the package.

#### Plugin based programming

It can reduce coupling of class inheritance using [plugin based development](http://miniim.blogspot.com/2014/09/plugin.html). This also helps to write modular code.

#### String

It has magnificent [string type, Xtring](../aroop/vapi/xtring.md). It reduces memory copy. It is possible to mark the string immutable(something like const ). It can be zero terminated on demand. Xtring can be allocated in stack memory as well as in heap. It is possible to manipulate binary data(not-ASCII data) in the form of strings.

#### defered statements 

TODO fill this up

#### Memory debugging

It aims to make memory debugging easier. For example there is a [memory profiler command in shotodol](https://github.com/kamanashisroy/shotodol/core/profiler/README.md) . It shows which module allocated memory, where and how much. It can also be debugged to see where exactly the referencing and dereferencing occurs.

#### Serialization and Message passing

It has high-level message passing framework as [shotodol.bundle](https://github.com/kamanashisroy/shotodol/libs/bundle/README.md). It serializes the data into memory bags. And it can be sent as message for example to the extension methods. Otherwise it is also possible to write message in database for interprocess communication like in [shotodol_db](https://github.com/kamanashisroy/shotodol_db).

#### Garbage collection

It has reference counted garbage collection system. It does not handle circular reference itself. The reference counting and object structure is just before the start of the object memory, so there is less memory operations.

#### Set/Vector/Array/Factory

It has a chunk of collection data which resides close together to be accessed and handled in less memory operation(caching). It uses memory pools for that. And it uses tree searching and hashing in hash tables and non-sparse arrays. These features are not directly availabe in Vala compiler and GObject library.

#### Concurrency

It is possible to send asynchronous message. There is [lock free queue](../aroop/vapi/queue.md) as message queue.

#### Namespaces

It has namespaces that helps to group code.

#### Exception handling

This reduces the code size.

#### Python like language integration.

Life is short. It is possible to write code in python and compile it with this Vala compiler. This is added by [Genie](http://en.wikipedia.org/wiki/Genie_(programming_language)). The same feature for Aroop is yet to come. 

#### Easy to learn

It has similarity with C,C++,C# and Java. The core idea of object oriented programming and functional programming are same. And syntaxes are very similar. So if someone knows any of those functional and object oriented programming languages then it will be easier for 
him to learn Vala.


#### Integrating low-level-code

It is possible to write low level code, such as C/assembly in it. It can be written as library and integrated with vapi file.

#### Portability

It generates code for C, so it can be ported in places where C is available. And C is available in most of the platforms.

#### It has object introspection developed over C 

It is possible to write object-oriented code in C using it's object introspection. 

#### Using the same language to write the compiler

Here the same language is used to write compiler. It makes available the features above for writing the compiler. This may be easier for users to change/modify it. There are plans to reorganize the code using plugin based approach.

### Current status

TODO fill me

###Comparison

#### C preprocessor
TODO fill me

[C preprocessor, by Richard Stallman](http://web.archive.org/web/20120904041038/http://docs.freebsd.org/info/cpp/cpp.pdf)

### Compiler

TODO Write about gcc and llvm.
Write about vala compiler. Write about roopantor.

#### Transforms
TODO K-normal forms
TODO Delegate conversions
TODO Nested expressions

#### Extending compiler

TODO say how we write a new feature extension plugin.

### Conclusion

Though Aroop is initially being developed to support the developement of scalable servers, it attracts the developers of other applications too. 


### Other proposals
[Lua proposal](http://lua-users.org/wiki/FeatureProposals)
[MinCaml Compiler](http://esumii.github.io/min-caml/index-e.html)
[Principles of programming languages](http://www.sigplan.org/Conferences/POPL/)





