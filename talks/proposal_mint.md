Aroop, the C code generator designed for writing scalable server
==========================================================

###1. Introduction

One of the main cause of using Aroop code generator is portability while using high level language. In fact the C programming language was popular because of universality and portability. The portability in C was achieved by compiling the universal C code into different non-portable assembly language. And Aroop is one way that portable because it can generate portable C code. Also it can use the existing C libraries by mapping them into api files. Furthermore Aroop uses high level language features and object pools. It is used to develop frameworks to build scalable servers.

###2. Developments

Aroop is a subset of [Vala programming language](https://wiki.gnome.org/Projects/Vala). The Aroop compiler is a fork of Vala compiler. And the programming languages are similar as well. Both of the compilers avoid any additional [ABI](https://wiki.gnome.org/action/recall/Projects/Vala?action=recall&rev=1). Both of them has the goal to use the existing C sources. The C programmers have to write a lot of boilerplate code to do simple things. These two compilers give the C programmers a way to write new code in Vala and still be able to integrate it with existing C libraries. The Vala project initially wanted to reduce boilerplate code needed for GObject based C programming. Thus it has GObject in it's core library. Aroop was developed as a compiler profile of Vala language. The idea behind Aroop is scalable server development. The Aroop does not use GObject, it uses [Object-Pool-Plus library](https://github.com/kamanashisroy/aroop/tree/master/aroop/core) as replacement. It has memory pools and an optional Red-Black tree available for searching. It has object tokens which is useful to reference objects via numbers. It has string type that reduces memory copy. And it has libraries to do message passing.

###3. Comparison

Aroop is very similar to some object oriented programming language compilers.

- Java and this language both are object oriented language. Both has similarities in syntax. But Java is compiled to bytecode and it needs jni to communicate with native code. On the other hand Aroop is compiled into C sources and it uses vapi to map the C code into vala. Again Aroop does not need VM for execution.
- Scalla is similar to Aroop because Scalla is high level language and both are source to source compilers. Scalla produces Java sources while Aroop produces C sources.
- C++ is similar in syntax though they have dissimilarities. C++ needs header files which is absent here. But both of them can use native C code readily. 
- C preprocessor is similar in a sense that it produces C sources.

###4. Compiler

This compiler is a choice of development and extension over the other compilers like gcc and llvm because of the works done already. Aroop is already in use. 

There is another compiler concept available named [Roopantor](https://github.com/kamanashisroy/roopantor). It is based on [shotodol](https://github.com/kamanashisroy/shotodol). The idea behind Roopantor is flexibility. It is ongoing project and it can also be used for experimental purpose to write new language features and test them. 

###5. Language features

In an effort to reduce boiler plate code and increase code reusability, there are some added features.

#####Syntactical features

- *No header files*: In C and C++ it takes time to write header files duplicating much of the code prototype. So it is not omitted here.
- *Delegate*: Delegates allow to write callbacks and it automatically captures the required variables in the scope.
- *Locally scoped functions and classes*: It has ways to hide the blocks of code and structures inside a package. It uses 'internal', 'private' and 'protected' access modifiers for this purpose. 
- *Python like language integration*: Life is short. It is possible to write code in python and compile it with this Vala compiler. This is added by [Genie](http://en.wikipedia.org/wiki/Genie_(programming_language)). The same feature for Aroop is yet to come. 
- *With expression*: When we operate on an object we repeatedly need to refer the fields of the objects again and again. We may reduce the retyping of the variable using a with statement.
- *Single lambda access operator*: It does not complicate things using both -> and . operators as in C. It uses only . operator. This reduces time to refactor the code.
- *Nullable and non-nullable variables*: It can be suggested if a variable is nullable. Non-nullable variable reduces the need to be checked for being null. It uses ? operator for nullable variables.

#####Design patterns

- *Plugin based programming*: Aroop is used to write [Shotodol](https://github.com/kamanashisroy/shotodol), a [plugin](https://github.com/kamanashisroy/shotodol/blob/master/libs/plugin) based server. The idea is to reduce coupling of class inheritance using [plugin based development](http://miniim.blogspot.com/2014/09/plugin.html). This also helps to write modular code.

![image](https://cloud.githubusercontent.com/assets/973414/3930915/c45b8232-244e-11e4-9ced-f277e9d48729.jpg)

- *Namespaces*:It has namespaces that helps to group code.
- *Exception handling*:This reduces the code size.

#####Memory management

- *String*: It has magnificent [string type, Xtring](https://github.com/kamanashisroy/aroop/tree/master/aroop/vapi/xtring.md). It reduces memory copy. It supports immutable, zero-terminated string, binary data and stack or heap allocation.
- *Garbage collection*: It has reference counted garbage collection system. It does not handle circular reference itself. 
- *Memory debugging*: It aims to make memory debugging easier. For example there is a [memory profiler command in shotodol](https://github.com/kamanashisroy/shotodol/core/profiler/README.md) . 
- *Serialization and Message passing*: It has high-level serialization framework as [shotodol.bundle](https://github.com/kamanashisroy/shotodol/libs/bundle/README.md). It is also possible to write message in database for interprocess communication like in [shotodol_db](https://github.com/kamanashisroy/shotodol_db).
- *Collection/Vector/Array/Factory*: The collection structures here provide tree based searching, hashing, flagging and non-sparse arrays.

#####Concurrency

- *Lock free queue*: It is possible to send asynchronous message. There is [lock free queue](https://github.com/kamanashisroy/aroop/tree/master/aroop/vapi/queue.md) implementation.
- *Multitasking*: It has both preemptive and non-preemptive multitasking. [Propeller](https://github.com/kamanashisroy/shotodol/blob/master/libs/propeller) is a thread. It is collection of _Spindles_. And it executes the _step()_ method of registered _Spindles_ one by one. [Turbine](https://github.com/kamanashisroy/shotodol/blob/master/libs/turbine) is a _Propeller_ that integrates the platform thread library. An application may contain only main thread which can perform _Propeller_ without the need of _Turbine_ . Otherwise if it contains multiple threads, it will need _Turbine_ to create them. 

#####Adaptability

- *Easy to learn*: It has similarity with C,C++,C# and Java. The core idea of object oriented programming and functional programming are same. And syntaxes are very similar. In fact vala is very popular in open-source community. 
- *It has object introspection developed over C*: It is possible to write object-oriented code in C using it's object introspection. 

###6. Deliverables

Currently [Aroop](https://github.com/kamanashisroy/aroop) compiles [shotodol](https://github.com/kamanashisroy/shotodol) and it is used to develop server applications. Now the idea is to make it flexible and write some benchmark projects. 

- Implement an HTTP server benchmarking module for [shotodol_web](https://github.com/kamanashisroy/shotodol_web), [Apache HTTP server benchmarking tool](http://httpd.apache.org/docs/2.0/programs/ab.html).
- Distributed ping-pong module for [shotodol_net](https://github.com/kamanashisroy/shotodol_net), Write distributed ping-pong module and evaluate performance. There is an example of such module is [available](http://www.erlang.org/doc/getting_started/conc_prog.html).
- Finish the [Roopantor](https://github.com/kamanashisroy/roopantor) project.
- Write a skeleton module for [Roopantor](https://github.com/kamanashisroy/roopantor) to add new features.

###7. Conclusion

Though Aroop is initially being developed to support the development of scalable servers, it attracts the developers of other applications too. 

###8.1. Talks
- [Game programming #1](https://www.youtube.com/watch?v=TH9VCN6UkyQ)
- [Game programming #2](https://www.youtube.com/watch?v=5Nc68IdNKdg)
- [Earlier talks on vala](https://wiki.gnome.org/action/recall/Projects/Vala?action=recall&rev=1)
- [Talk on vala](http://www.linux-magazin.de/Online-Artikel/Vorteile-kombinieren)

###8.2. Other projects
- [Ejabberd](https://www.ejabberd.im/) is very popular scalable [XMPP server](https://en.wikipedia.org/wiki/XMPP).
- [Asterisk](http://www.asterisk.org/)
- [Nodejs addon](http://www.nodejs.org/api/addons.html)

###8.3. Other related proposals
- [Lua proposal](http://lua-users.org/wiki/FeatureProposals)
- [Bedrock](http://plv.csail.mit.edu/bedrock/)

###8.4. Readings
- [Principles of programming languages](http://www.sigplan.org/Conferences/POPL/), [mentor](http://plmw2014.inria.fr/program.html)
- [Constructive mathematics and computer programming](http://www.cs.tufts.edu/~nr/cs257/archive/per-martin-lof/constructive-math.pdf)
- [C preprocessor, by Richard Stallman](http://web.archive.org/web/20120904041038/http://docs.freebsd.org/info/cpp/cpp.pdf)

###8.5. Links

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



