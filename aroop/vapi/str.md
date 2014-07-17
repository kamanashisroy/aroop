
Aroop contains special support for strings. The aroop strings has support for,

- Embeded/stack allocated container.
- Stack allocated string.
- Heap allocated string.
- A hash value and precalculated length value.
- There are plans to implement immutable strings.

The strings can be referenced in your code when it is allocated in heap. You can avoid memory copy by just referencing the heap string. For example, if you have a string named `hello`, you may define it like the following.

```vala
str hello = new str.copy_static_string("hello");
```

This will allocate a memory in heap for *str* structure as well as the "hello" string. You can do either [deep_copy](http://en.wikipedia.org/wiki/Deep_copy#Deep_copy) or [shallow_copy](http://en.wikipedia.org/wiki/Deep_copy#Shallow_copy) or [copy_on_demand](http://en.wikipedia.org/wiki/Deep_copy#Lazy_copy) of this string.

Again you can also allocate memory in stack.

```vala
estr hello = new estr.set_static_string("hello");
```

The above code will keep the string totally in stack memory. You may also allocate stack memory if you want like the following.


```vala
estr hello = new estr.stack(128);
hello.concat_string("hello");
```

Now suppose you want to pass by value and set the estr parameter to a method. You can do that like the following.

```vala
	public void getAs(estr*content) {
                content.rebuild_and_copy_on_demand(&cache);
        }
```


TODO: write more about coping and referencing strings.

