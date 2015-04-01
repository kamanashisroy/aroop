Aroop
=======

This is compiler backend/profile for vala. It generates C code for given Vala sources. The generated code is targeted for server applications and for the applications that do not want to use gobject-introspection. This library is dependent on own object implementation named Object Pool Plus.

###[Object Pool Plus](https://github.com/kamanashisroy/opp_factory)
This is a library to manipulate collection of objects and for garbage collection. This library is used in complimentary [core](aroop/core/README.md) library for aroop generated code. This library is an implementation of [*object pool*](http://en.wikipedia.org/wiki/Object_pool).

###core api
The [core api](aroop/vapi/README.md) contains [string](aroop/vapi/xtring.md) and collection manipulation api.

Building
========

### Requirements
The following projects are needed to build aroopc.
- autoconf
- automake
- libtool
- valac (If the aroop project does not come with generated C files) (currently it is compiled with vala-26 version)
- libgee (please install the development version too)
- C compiler (gnu C compiler for example)

### Getting aroop source
Aroop is hosted in [github](https://github.com/kamanashisroy/aroop). It can be *cloned* form `https://github.com/kamanashisroy/aroop.git` . Or it can be downloaded [here](https://github.com/kamanashisroy/aroop/archive/master.zip).

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
Well if _autogen_ command above fails and it says it needs right version of vala, then the right version of [vala](https://wiki.gnome.org/Projects/Vala/Hacking#Compiling_from_Git) needs to be installed first(in my system it is 26). After installation it is needed to carry out the following commands as well,

```
a/aroop$ export VALAC=/opt/vala-26/bin/valac # skip this if it is installed right version to default location
a/aroop$ cp /opt/vala-26/lib/pkgconfig/libvala-0.26.pc /usr/lib/pkgconfig/ # skip this if it is installed right version to default location
a/aroop$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/vala-26/lib # skip this if it is installed right version to default location
a/aroop$ ldconfig # skip this if it is installed right version to default location
```

Now that vala is installed successfully, the previous procedures can be carried out starting from _autogen_.

Compiling hello world
==================

Compiling the code is comprised of two stages. Suppose the target vala file name is `hello_world.vala`.

```vala
using aroop;

class HelloWorld {
	public static void main() {
		print("Hello world\n");
	}
}
```

### Generating C code
At first the *aroopc* generates C code output. It creates `hello_world.c` file for the source `hello_world.vala`.

```
a/tmp$ /opt/aroop/bin/aroopc -C hello_world.vala
a/tmp$ ls
hello_world.c
```

The `hello_world.c` contains all the instructions in `hello_world.vala`.

###Compiling the C code
Now the the C source can be compiled using C compiler. If gnu C compiler is used then the following command will serve the purpose.

```
a/tmp$ gcc -I/opt/aroop/include/aroop hello_world.c /opt/aroop/bin/libaroop_core.o -o hello_world.bin # link statically
a/tmp$ gcc -I/opt/aroop/include/aroop hello_world.c /opt/aroop/lib/libaroop_core_static.a  -o hello_world.bin # linking statically
a/tmp$ gcc -I/opt/aroop/include/aroop hello_world.c -L/opt/aroop/lib -laroop_core -o hello_world.bin # link dynamically
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

###Compiling genie

[Genie](http://en.wikipedia.org/wiki/Genie_%28programming_language%29) syntax is derived from numerous modern languages like Python, Boo, D and Delphi.

```genie
// file hello_world.gs
uses aroop

init
        print "Hello world"

```
The following commands will compile genie.

```
a/tmp$ /opt/aroop/bin/aroopc hello_world.gs
a/tmp$ ./hello_world
Hello world
```


###Compiling a bare metal image for raspberry pi

Details is [here](aroop/core/build/raspberry_pi_bare_metal/README.md).

More
=====
Please refer to [vala readme](README) for more information. There are more documents in the [talks](talks) directory,

- [Features](talks/features.md)
- [Data oriented programming](talks/data_oriented_talks/)
- [talks](talks/)

Public projects using aroop
============================
- [Shotodol](https://github.com/kamanashisroy/shotodol)
- [Roopkotha](https://github.com/kamanashisroy/roopkotha)
- [Onubodh](https://github.com/kamanashisroy/onubodh)

TASKS
=====

[Tasks](aroop/TASKS.md)

