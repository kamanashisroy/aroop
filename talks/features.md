
Why use aroop ?

It reduces friction and gives you motion inertia in several ways,

#### It reduces writing/mentioning types while you are declaring variables.

You can use duck-type 'var' for variable declaration.

#### It has no header files.

In C and C++ you need to take time to write header files duplicating much of your code. But you do not need to do it here. It is more like java in this way.

#### It uses closures

In some languages writing callback is either complex or needs memory allocation in some languages (for example in Java). You can write callback easily here using delegate. And it captures the required variables in the scope(you do not need to specify them explicitly).

#### Single lambda access delemiter

It does not complicate things using both '->' and '.' delimiters. It uses only '.'. It reduces time to refactor you code. 

#### Nullable and non-nullable variables

You can suggest if a variable is nullable thus you can reduce null checking. see '?' parameter.

#### Locally scoped function and Classes

It helps to hide your blocks of codes and structures inside a package. This helps you to modify them later without worrying about how they are used outside(because they do not live outside). It uses 'internal', 'private' and 'protected' for this purpose.

#### Plugin oriented programming

You can reduce complexity of class inheritance using [plugin oriented development](http://miniim.blogspot.com/2014/09/plugin.html). This also helps you write modular code.

#### String

It has magnificent [string types](../aroop/vapi/xtring.md). You have ways to reduce memory copy and mark your string immutable(something like in const ). You can also zero terminate it easily. You can allocate strings in stack memory. You can also manipulate binary data(not-ASCII data) in the form of strings.

#### Memory debugging

Check the [memory profiler command in shotodol](https://github.com/kamanashisroy/shotodol/core/profiler/README.md) . It shows which module allocated memory, where and how much. You can also debug to see where exactly the referencing and dereferencing occurs. 

#### Serialization and Message passing

It has high-level message passing frameworks, see [shotodol.bundle](https://github.com/kamanashisroy/shotodol/libs/bundle/README.md). It serializes the data into memory bags. And you can send them as message. An easy way to put memory is to use the extension methods. Otherwise you can write message in database for interprocess communication like in [shotodol_db](https://github.com/kamanashisroy/shotodol_db).

#### Garbage collection

We have reference counting garbage collection system. It does not handle circular reference itself. The reference counting and object structure is just before the start of the object memory, so there is less memory operations and it is fast.

#### Set/Vector/Array/Factory

We have a chunk of collection data which resides close together to access and handle them quickly. It uses memory pools for that. And it uses tree searching and hashing in hash tables and non-sparse arrays. These has something to do with performance.

#### Concurrency

You can implement asynchronous message passing technique. Or you can use [lock free queue](../aroop/vapi/queue.md) for communication.

#### Namespaces

It has namespaces that helps to sort your code.

#### Exception handling

This reduces the code size.

#### It has python like language integration.

You can write things even shorter like in python language here. This is added by [Genie](http://en.wikipedia.org/wiki/Genie_(programming_language)).

#### Easy to learn

If you are already a programmer and you know C and Java or C# then you will find Aroop easy to use.

#### Integrating performance-code/low-level-code

It supports you to integrate low level code, such as C/assembly into it. You can easily write vapi file to amalgamate the C implementation.

#### Portability

It generates code for C, so it can be ported in places where C is available.

#### It has object introspection developed over C 

You may use the object introspection in your C implementation.

#### Data programming best practices

TODO say something here.

#### Using the same language to write the compiler

We are using the same language to write compiler. It makes available the features(which we talked here) for writing the compiler. And it will be easier for users to change/modify it.

TALKS
=====
- [Game programming #1](https://www.youtube.com/watch?v=TH9VCN6UkyQ)
- [Game programming #2](https://www.youtube.com/watch?v=5Nc68IdNKdg)
- [Earlier talks](https://wiki.gnome.org/action/recall/Projects/Vala?action=recall&rev=1)
- [Another talk](http://www.linux-magazin.de/Online-Artikel/Vorteile-kombinieren)
