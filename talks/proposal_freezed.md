Aroop, the C code generator designed for writing scalable server
==========================================================

###1. Abstract

One of the main cause of using Aroop code generator is portability while using high level language. In fact the C programming language was popular because of universality and portability. The portability in C was achieved by compiling the universal C code into different non-portable assembly language. And Aroop is one way that portable because it can generate portable C code. Also it can use the existing C libraries by mapping them into api files. Furthermore Aroop uses high level language features and object pools. It is used to develop frameworks to build scalable servers.

###### Tags
Programming language, Compiler, Code generator, High level language, Object oriented language

###2. Summary

Aroop is a subset of [Vala programming language](https://wiki.gnome.org/Projects/Vala). The Aroop compiler is a fork of Vala compiler. And the programming languages are similar as well. Both of the compilers avoid any additional [ABI](https://wiki.gnome.org/action/recall/Projects/Vala?action=recall&rev=1). Both of them has the goal to use the existing C sources. The C programmers have to write a lot of boilerplate code to do simple things. These two compilers give the C programmers a way to write new code in Vala and still be able to integrate it with existing C libraries. The Vala project initially wanted to reduce boilerplate code needed for GObject based C programming. Thus it has GObject in it's core library. Aroop was developed as a compiler profile of Vala language. The idea behind Aroop is scalable server development. The Aroop does not use GObject, it uses [Object-Pool-Plus library](https://github.com/kamanashisroy/aroop/tree/master/aroop/core) as replacement. It has memory pools and an optional Red-Black tree available for searching. It has object tokens which is useful to reference objects via numbers. It has string type that reduces memory copy. And it has libraries to do message passing.


###3.1. Language features(syntax)


#### Duck typing

It reduces the need of mentioning the variable type while declaration. The expression below declares a variable of type Mango in Java.

```
Mango x = new Mango();
```

The same thing is done below in Vala.

```
var x = new Mango();
```

Clearly it reduces the number of mention of the type.

#### No header files

In C and C++ it takes time to write header files duplicating much of the code prototype. But this is not needed in Aroop. The same feature is available in Java too. Defining a Class in Vala source files is all it needs for linking.

For external linking Aroop(and Vala) automatically generates prototypes of the classes. They are listed in a file called vapi files.

#### Delegate

In some languages writing callback is either complex or needs memory allocation (for example in Java). Here it is easy to do using delegates. And it automatically captures the required variables in the scope(it is not needed to specify them explicitly as in C++). An example of such delegate is shown below.

```
// count variable declaration
int count = 0;
ar.visit_each((x) => {
	// the count variable is accessed from outer scope
	count = x.calc();
}, Replica_flags.ALL);
```
The code above generates C structures automatically to capture the local variables. It then passes them as parameter to visit_each() function. 

#### Single lambda access operator

It does not complicate things using both `->` and `.` operators as in C. It uses only `.` operator. This reduces time to refactor the code. 

#### Nullable and non-nullable variables

It can be suggested if a variable is nullable. Non-nullable variable reduces the need to be checked for being null. It uses `?` operator for nullable variables.

```
var? x = new Mango();
```

#### Locally scoped functions and classes

It has ways to hide the blocks of code and structures inside a package. It uses 'internal', 'private' and 'protected' access modifiers for this purpose. This helps to modify them later without worrying about how they are used outside(because they do not live outside) of the package. This helps to write black boxes.

#### Python like language integration.

Life is short. It is possible to write code in python and compile it with this Vala compiler. This is added by [Genie](http://en.wikipedia.org/wiki/Genie_(programming_language)). The same feature for Aroop is yet to come. 

#### Deferred statements 

Sometimes we acquire a resource and we need to get them free. In those cases we may defer a free statement to be executed before the function or block exits. This feature is planned to be added in future.


#### With expression

When we operate on an object we repeatedly need to refer the fields of the objects again and again. We may reduce the retyping of the variable using a _with_ statement. For example, we may reduce the following code.

```
object.do1();
object.do2();
object.do3();
```

The same thing is done using _with_ statement below.

```
with object {
	do1(); do2(); do3();
}
```


###3.2. Language features(design patterns)

#### Plugin based programming

Plugin based programming is a way to develop the features as plugins. It has lots of advantages over the kitchen-sink approach. Aroop is used to write [Shotodol](https://github.com/kamanashisroy/shotodol), a [plugin](https://github.com/kamanashisroy/shotodol/blob/master/libs/plugin) based server. The idea is to reduce coupling of class inheritance using [plugin based development](http://miniim.blogspot.com/2014/09/plugin.html). This also helps to write modular code.

![image](https://cloud.githubusercontent.com/assets/973414/5548616/ffe8add0-8b9f-11e4-9660-5e96311ea880.jpg)

#### Namespaces

It has namespaces that helps to group code.

#### Exception handling

This reduces the code size.

###3.4. Language features(memory management)

#### String

It has magnificent [string type, Xtring](https://github.com/kamanashisroy/aroop/tree/master/aroop/vapi/xtring.md). It reduces memory copy. It is possible to mark the string immutable(something like const ). It can be zero terminated on demand. Xtring can be allocated in stack memory as well as in heap. It is possible to manipulate binary data(non-ASCII data) in the form of strings.

#### Garbage collection

It has reference counted garbage collection system. It does not handle circular reference itself. The reference counting and object structure is just before the start of the object memory, so there is less memory operations.

#### Memory debugging

It aims to make memory debugging easier. For example there is a [memory profiler command in shotodol](https://github.com/kamanashisroy/shotodol/core/profiler/README.md) . It shows which module allocated memory, where and how much. It can also be debugged to see where exactly the referencing and dereferencing occurs.

#### Serialization and Message passing

It has high-level message passing framework as [shotodol.bundle](https://github.com/kamanashisroy/shotodol/libs/bundle/README.md). It serializes the data into memory bags. And it can be sent as message for example to the extension methods. Otherwise it is also possible to write message in database for interprocess communication like in [shotodol_db](https://github.com/kamanashisroy/shotodol_db).

#### Set/Vector/Array/Factory

It has a chunk of collection data which resides close together to be accessed and handled in less memory operation(caching). It uses memory pools for that. And it uses tree searching and hashing in hash tables and non-sparse arrays. Furthermore it is possible to traverse the elements of the collection based on their flags. These features are not directly available in Vala compiler and GObject library.

###3.5. Language features(Concurrency)

#### Lock free queue

It is possible to send asynchronous message. There is [lock free queue](https://github.com/kamanashisroy/aroop/tree/master/aroop/vapi/queue.md) implementation.

#### Multitasking

It has both preemptive and non-preemptive multitasking.

[CompositeFiber](https://github.com/kamanashisroy/shotodol/blob/master/libs/fiber) is a thread. It is collection of _Fiber_s. And it executes the _step()_ method of registered _Fiber_s one by one. If _step()_ returns nonzero then it is oust from the execution line.

[SpinningWheel](https://github.com/kamanashisroy/shotodol/blob/master/libs/spinningwheel) is a _CompositeFiber_ that integrates the platform thread library. An application may contain only main thread which can perform _CompositeFiber_ without the need of _SpinningWheel_ . Otherwise if it contains multiple threads, it will need _SpinningWheel_ to create them. 

###3.6. Language features(Adaptability)

#### Easy to learn

It has similarity with C,C++,C# and Java. The core idea of object oriented programming and functional programming are same. And syntaxes are very similar. So if someone knows any of those functional and object oriented programming languages then it will be easier for him to learn Vala. In fact vala is very popular in open-source community. 


#### Integrating low-level-code

It is possible to write low level code, such as C/assembly in it. It can be written as library and integrated with vapi files.

#### Portability

It generates code for C, so it can be ported in places where C is available. And C is available in most of the platforms.

#### It has object introspection developed over C 

It is possible to write object-oriented code in C using it's object introspection. 

#### Using the same language to write the compiler

Here the same language is used to write compiler. It makes available the features above for writing the compiler. This may be easier for users to change/modify it. There are plans to reorganize the code using plugin based approach.

###4. Comparison

Aroop is very similar to some object oriented projects.

- Java and this language both are object oriented language. Both has similarities in syntax. But Java is compiled to bytecode and it needs jni to communicate with native code. On the other hand Aroop is compiled into C sources and it uses vapi to map the C code into vala. Again Aroop does not need VM for execution.
- Scalla is similar to Aroop because Scalla is high level language and both are source to source compilers.
- C++ is similar in syntax though they have dissimilarities. C++ needs header files which is absent here. But both of them can use native C code readily. 
- C preprocessor is similar in a sense that it produces C sources.

###5. Compiler

This compiler is a choice of development and extension over the other compilers like gcc and llvm because of the works done already. Aroop is already in use. There is another compiler concept available named [Roopantor](https://github.com/kamanashisroy/roopantor). That project is created for an ease of development and extension. It has the same philosophy of [shotodol](https://github.com/kamanashisroy/shotodol). And it is written in Aroop language. The idea behind Roopantor is flexibility. It is ongoing project and it can also be used for experimental purpose to write new language features and test them. 

#### Extending compiler

The extension mechanism is provided by plugin. So it will be easy to add new plugin to add new feature. The [Roopantor](https://github.com/kamanashisroy/roopantor) project structure is ideal for that purpose.


###6. Current status

Currently [Aroop](https://github.com/kamanashisroy/aroop) compiles [shotodol](https://github.com/kamanashisroy/shotodol) and it is used to develop server applications.

###7. Conclusion

Though Aroop is initially being developed to support the development of scalable servers, it attracts the developers of other applications too. 

###8.1. Other related proposals
- [Principles of programming languages](http://www.sigplan.org/Conferences/POPL/), [mentor](http://plmw2014.inria.fr/program.html)
- [Lua proposal](http://lua-users.org/wiki/FeatureProposals)
- [MinCaml Compiler](http://esumii.github.io/min-caml/index-e.html)
- [Ivory programming language](http://ivorylang.sourceforge.net/)
- [Bedrock](http://plv.csail.mit.edu/bedrock/)

###8.2. Readings
- [Constructive mathematics and computer programming](http://www.cs.tufts.edu/~nr/cs257/archive/per-martin-lof/constructive-math.pdf)
- [C preprocessor, by Richard Stallman](http://web.archive.org/web/20120904041038/http://docs.freebsd.org/info/cpp/cpp.pdf)

###8.3. Links

- [Aroop](https://github.com/kamanashisroy/aroop)
- [Roopantor](https://github.com/kamanashisroy/roopantor)
- [Shotodol](https://github.com/kamanashisroy/shotodol)
   - [Shotodol Net](https://github.com/kamanashisroy/shotodol_net)
   - [Shotodol Web](https://github.com/kamanashisroy/shotodol_web)
   - [Shotodol DB](https://github.com/kamanashisroy/shotodol_db)
   - [Onubodh](https://github.com/kamanashisroy/onubodh)
- [Roopkotha](https://github.com/kamanashisroy/roopkotha)
- [Blog](https://miniim.blogspot.com)
- [Github](https://github.com/kamanashisroy)
- [Vala](https://wiki.gnome.org/Projects/Vala)


###8.4. Talks
- [Game programming #1](https://www.youtube.com/watch?v=TH9VCN6UkyQ)
- [Game programming #2](https://www.youtube.com/watch?v=5Nc68IdNKdg)
- [Earlier talks](https://wiki.gnome.org/action/recall/Projects/Vala?action=recall&rev=1)
- [Another talk](http://www.linux-magazin.de/Online-Artikel/Vorteile-kombinieren)

###8.5. Other projects
- [Ejabberd](https://www.ejabberd.im/) is very popular scalable [XMPP server](https://en.wikipedia.org/wiki/XMPP).
- [Asterisk](http://www.asterisk.org/)
- [Nodejs addon](http://www.nodejs.org/api/addons.html)
