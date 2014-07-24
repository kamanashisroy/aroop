Aroop
=======

This is compiler profile for vala. This profile is targeted for server applications and for the applications that do not want to use gobject-introspection. This library is dependent on own object implementation named Object Pool Plus.

###[Object Pool Plus](https://github.com/kamanashisroy/opp_factory)
This is a library to manipulate collection of objects and for garbage collection. This library is used in complimentary [core](aroop/core/README.md) library for aroop profile bulild. This library is an implementation of [*object pool*](http://en.wikipedia.org/wiki/Object_pool).

###core api
The [core api](aroop/vapi/README.md) contains string and collection manipulation api.

Getting Aroop
=============

Aroop is hosted in [github](https://github.com/kamanashisroy/aroop). You can either *clone* the project using git form `https://github.com/kamanashisroy/aroop.git` . Or you can download it [here](https://github.com/kamanashisroy/aroop/archive/master.zip).

Building
========

### Requirements
You need the following projects to build aroopc.
- automake
- libtool
- valac (If the aroop project does not come with generated C files)
- C compiler (gnu C compiler for example)

### Compiling aroopc

Aroop uses the same [automake tool-chain](http://www.gnu.org/software/automake/manual/automake.html) as [vala](https://wiki.gnome.org/Projects/Vala/Hacking#Compiling_from_Git). You may do it using the following commands,

```
a/aroop$ export VALAC=/opt/vala-release/bin/valac # skip this if you installed right version of valac from binary package
a/aroop$ export LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):/opt/vala-release/lib # skip this if you installed right version of valac from binary package
a/aroop$ ldconfig # skip this if you installed right version of valac from binary package
a/aroop$ ./autogen.sh --prefix=/opt/aroop
a/aroop$ make
a/aroop$ ls aroop/compiler/
aroopc
a/aroop$ make install
a/aroop$ ls /opt/aroop/bin
aroopc
```

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
a/tmp$ /opt/aroop/bin/aroopc hello_world.vala
a/tmp$ ./hello_world.bin
Hello world
```

You may learn more about vala code compiling [here](https://wiki.gnome.org/Projects/Vala/Documentation) [here](https://wiki.gnome.org/Projects/Vala/BasicSample).

More
=====
Please refer to [vala readme](README) for more information.
