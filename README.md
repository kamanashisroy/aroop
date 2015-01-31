Aroop
=======

This is compiler profile for vala. This profile is targeted for server applications and for the applications that do not want to use gobject-introspection. This library is dependent on own object implementation named Object Pool Plus.

###[Object Pool Plus](https://github.com/kamanashisroy/opp_factory)
This is a library to manipulate collection of objects and for garbage collection. This library is used in complimentary [core](aroop/core/README.md) library for aroop profile bulild. This library is an implementation of [*object pool*](http://en.wikipedia.org/wiki/Object_pool).

###core api
The [core api](aroop/vapi/README.md) contains [string](aroop/vapi/xtring.md) and collection manipulation api.

Building
========

### Requirements
You need the following projects to build aroopc.
- automake
- libtool
- valac (If the aroop project does not come with generated C files)
- C compiler (gnu C compiler for example)

### Getting aroop source
Aroop is hosted in [github](https://github.com/kamanashisroy/aroop). You can either *clone* the project using git form `https://github.com/kamanashisroy/aroop.git` . Or you can download it [here](https://github.com/kamanashisroy/aroop/archive/master.zip).

### Compiling aroopc

Aroop uses the same [automake tool-chain](http://www.gnu.org/software/automake/manual/automake.html) as [vala](https://wiki.gnome.org/Projects/Vala/Hacking#Compiling_from_Git). If you are compiling a GNU software for the first time, then I strongly suggest you read [this document](http://autotoolset.sourceforge.net/tutorial.html#Installing-GNU-software). You may do it using the following commands,

```
a/aroop$ ./autogen.sh --prefix=/opt/aroop
a/aroop$ make
a/aroop$ ls aroop/compiler/
aroopc
a/aroop$ make install
a/aroop$ ls /opt/aroop/bin
aroopc
```

##### If _autogen_ failed to find right vala version
Well if _autogen_ command above fails and it says it needs right version of vala, then you need to install right version of [vala](https://wiki.gnome.org/Projects/Vala/Hacking#Compiling_from_Git) first(in my system it is 14). After installation you may need to carry out the following commands as well,

```
a/aroop$ export VALAC=/opt/vala-14/bin/valac # skip this if you installed right version of valac from binary package
a/aroop$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/vala-14/lib # skip this if you installed right version of valac from binary package
a/aroop$ ldconfig # skip this if you installed right version of valac from binary package
```

Now that you have installed vala, you can carry out the previous commands starting from _autogen_ .

Compiling your code
==================

Compiling your code is comprised of two stages. Suppose you have a vala file named `hello_world.vala`.

```vala
using aroop;

class HelloWorld {
	public static void main() {
		print("Hello world\n");
	}
}
```

### Generating C code
At first the *aroopc* generates C code output. For example, if you have `hello_world.vala` file then it will create `hello_world.c` file.

```
a/tmp$ /opt/aroop/bin/aroopc -C hello_world.vala
a/tmp$ ls
hello_world.c
```

Now the `hello_world.c` contains all the instructions in `hello_world.vala`.

###Compiling the C code
You can compile the C source using C compiler. Suppose if you use gnu C compiler then the following command will work for you.

```
a/tmp$ gcc -I/opt/aroop/include/aroop hello_world.c /opt/aroop/bin/libaroop_core.o-0.16 -o hello_world.bin # you can link statically
a/tmp$ gcc -I/opt/aroop/include/aroop hello_world.c /opt/aroop/lib/libaroop_core_static.a  -o hello_world.bin # you can link statically
a/tmp$ gcc -I/opt/aroop/include/aroop hello_world.c -L/opt/aroop/lib -laroop_core -o hello_world.bin # or you can link dynamically
a/tmp$ ls
hello_world.bin
a/tmp$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/aroop/lib # you need to set the dynamic library path
a/tmp$ ldconfig # reset library finder
a/tmp$ ./hello_world.bin
Hello world
```

### One step compilation
Once you installed the package file in `/usr/lib/pkgconfig`, you can compile a source in one step.

```
a/tmp$ install /opt/aroop/lib/pkgconfig/aroop_core-1.0.pc /usr/lib/pkgconfig
a/tmp$ /opt/aroop/bin/aroopc hello_world.vala -o hello_world.bin
a/tmp$ ./hello_world.bin
Hello world
```

The above binary will need the shared library to run. You can also build standalone binary using --static-link argument.
```
a/tmp$ install /opt/aroop/lib/pkgconfig/aroop_core-1.0.pc /usr/lib/pkgconfig
a/tmp$ /opt/aroop/bin/aroopc --static-link hello_world.vala
a/tmp$ ./hello_world.bin
Hello world
```
You may optionally put a `--debug` option while doing static linking. This will create a debug build, which you may want to trace and debug.
You may learn more about vala code compiling [here](https://wiki.gnome.org/Projects/Vala/Documentation) and [here](https://wiki.gnome.org/Projects/Vala/BasicSample).

###Compiling a bare metal image for raspberry pi

Details is [here](aroop/core/build/raspberry_pi_bare_metal/README.md).

More
=====
Please refer to [vala readme](README) for more information. There are more documents in the [talks](talks) directory,

- [Features](talks/features.md)
- [Data oriented programming](talks/data_oriented_talks/)
- [talks](talks)

Public projects using aroop
============================
- [Shotodol](https://github.com/kamanashisroy/shotodol)
- [Roopkotha](https://github.com/kamanashisroy/roopkotha)
- [Onubodh](https://github.com/kamanashisroy/onubodh)

TASKS
=====

[Tasks](aroop/TASKS.md)

