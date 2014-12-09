aroop core
===========

This is complimentary C library for the aroop generated code.

Building
========

Building core library binary is trivial. You need to put `make` command and that is all.

```
a/aroop$ cd aroop/core
a/aroop/aroop/core$ make
...
...
a/aroop/aroop/core$ ls
libaroop_core_static.a libaroop_core_debug.a libaroop_core_basic.o  libaroop_core.o 
```

After build we shall get the object files(*libaroop_core_basic.o*,*libaroop_core.o*) and also an archive(*libaroop_core.a*). You may link them to your binary using `-laroop_core` flag. Otherwise you can also link the object file(*libaroop_core.o*) with the binary.

Internals
==========

[virtual method table](http://en.wikipedia.org/wiki/Virtual_method_table)

Reading
========

- [The Basic Program/System Interface](http://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_chapter/libc_25.html)
- [obstacks](http://www.gnu.org/software/libc/manual/html_node/Obstacks.html#Obstacks)
- [ZeroMQ](http://aosabook.org/en/zeromq.html), is a message passing library that uses less memory copy and less system call. It uses batching and memory pooling.

