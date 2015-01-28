Response to [talk](https://www.youtube.com/watch?v=ZHqFrNyLlpA)
===============================================================

Jonathan Blow gave [a talk](https://www.youtube.com/watch?v=ZHqFrNyLlpA) on programming language. Here we shall discuss the vala way to do that, specifically we will use [aroop](www.github.com/kamanashisroy/aroop) profile for vala language to investigate the whole thing.


#### Multiple heap allocation and cache miss.

He says the multiple heap allocation problem.

In vala, we have hierarchy,

```vala
public class Entity : Replicable {
	protected Vector3 position;
	protected void do_my_thing() {
		position.x += 1;
	}
	protected virtual void do_other_thing();
}
public class Door : Entity {
	floor current;
	protected override void do_other_thing() {
		current += 5;
	}
}
```

And the above code will generate the following code and it will need only one heap allocation.

```C
struct Entry {
	vector3 position;
	void*(do_my_thing)(Entity*x);
	struct Entity_vtable {
		void (do_other_thing*)(Entity*x);
	}*vtable;
}

struct Door {
	Entity entity;
	floor current;
}

void do_my_thing(Entity*x) {
	x->position.x += 1;
}

void door_other_thing(Entity*x) {
	Door door = (Door)x;
	door.current += 5;
}

struct Entity_vtable door_ovrride_entity = {
	door_other_thing,
}

```

#### The element access problem.

In C structures like the following we need to write `door.entity.position` to access the value, but in vala it is just `door.position` .

```C
struct Entry {
	vector3 position;
	void*(do_my_thing)(Entity*x);
	struct Entity_vtable {
		void (do_other_thing*)(Entity*x);
	}*vtable;
}

struct Door {
	Entity entity;
	floor current;
}
```

Furthermore `door.do_other_thing()` will work out of box and the underlying C code is without any memory operation or type checkup.

```C
	door.entity.vtable->do_other_thing((Entity*)&door); // very simple and easy
```

#### Element access using _with_ or _using_ statement

The idea to use the _using_ statement is to reduce the source prefix to identify a variable. Suppose in the previous example, we need to write `door.do_other_ting(); door.do_my_thing()`. With the use of _with_ statement we can do the same thing like the following,

```Vala
with(door) {
	do_other_thing();
	do_my_thing();
}
```

The code above reduced the need to specify _door_ in every element access. This is a proposed feature for Vala but it is not already there.

#### Using entity by value and entity by pointer

I think this stuff is not needed as we have those already in our class hierarchy.

#### Multiple entity

This is getting complicated. Getting things complicated is something I do not support. But some of the goals may be achieved in the following sections.

```Vala
public class Door : Replicable {
	//Entity*entity;
	floor current;
	protected void do_my_thing(Entity*x) {
		x.do_my_thing();
	}
	protected void do_other_thing() {
		current += 5;
	}
}
```

#### SOA array

In aroop profile we use memory pools for managing heaps. Please notice the HOT and COLD data.

```Vala
public class Board : Replicable { /* Here it is bulgy COLD data */
	int mask; // color mask
	uchar data[512];
	public void build() {
		core.memclean(data);
		mask = 0;
	}
	public void set(int color, int pos) {
		if(pos >= 512) return;
		data[pos] = color & mask;
	}
	public void dump() {
		int i = 0;
		for(i = 0; i < 512; i++)
			if(data[i] != 0)
				print("%d,", i);
		print("\n");
	}
}

public class Pen : Replicable { /* This is compact HOT data */ 
	int radius;
	int color;
	public void build(int rad, int givenColor) {
		radius = rad;
		color = givenColor;
	}
	public void draw(Board bd, int pos) {
		int i = 0;
		for(i=0;i<radius;i++) {
			bd.set(color, pos+i);
		}
	}
}
public class WritingStuff : Replicable { // SOA structure
	SearchableFactory<Pen> pens; // kind of memory pool/array
	Factory<Board> boards; // Array/pool
	WritingStuff() {
		pens = SearchableFactory<Pen>();
		boards = Factory<Board>();
	}
	public void buildPen(int radius, int color) {
		Pen x = pens.alloc();
		x.build(radius, color);
		x.set_hash(radius);
	}
	public void buildBoard() {
		Board bd = boards.alloc();
		bd.build();
	}
	public void write(int radius, Board bd, int pos) {
		Pen x = pens.search(radius);
		x.draw(bd, pos);
	}
	public void writeAll(int radius, int pos) {
		Pen x = pens.search(radius);
		Iterator<Board> iboard = Iterator();
		boards.getIterator(&iboard);
		while(iboard.next()) { // This is inline thing and it is fast enough I believe.
			Board board = iboard.get();
			x.write(board, pos);
		}
	}
	public void dump() {
		Iterator<Board> iboard = Iterator();
		boards.getIterator(&iboard);
		while(iboard.next()) { // This is inline thing and it is fast enough I believe.
			Board board = iboard.get();
			board.dump();
		}
	}
}
public class MainClass : Replicable {
	public static main() {
		WritingStuff tool = new WritingStuff();
		tool.buildPen(2, 6);
		tool.buildBoard();
		tool.writeAll(2, 4);
		tool.dump();
	}
}
```
Here in the code we use pool to address the SOA. I think this will be good for Intel suggestion. Additionally it reduces the need for sparse array.

#### Refactoring the SOA array

Refactoring is easy if you can encapsulate your code in functions. In the example above we moved _mask_ into _Pen_ and we get the following classes.
```Vala
public class Board : Replicable { /* Here it is bulgy COLD data */
	uchar data[512];
	public void build() {
		core.memclean(data);
	}
	public void set(int color, int pos) {
		if(pos >= 512) return;
		data[pos] = color;
	}
	public void dump() {
		int i = 0;
		for(i = 0; i < 512; i++)
			if(data[i] != 0)
				print("%d,", i);
		print("\n");
	}
}

public class Pen : Replicable { /* This is compact HOT data */ 
	int radius;
	int color;
	int mask; // color mask
	public void build(int rad, int givenColor) {
		radius = rad;
		color = givenColor;
	}
	public void draw(Board bd, int pos) {
		int i = 0;
		int mycolor = mask & color;
		for(i=0;i<radius;i++) {
			bd.set(mycolor, pos+i);
		}
	}
}
```

But the rest of the stuff is unchanged.

#### vtables

This is hidden for Vala.

```Vala
public class Board : Replicable { /* Here it is bulgy COLD data */
	uchar data[512];
	public void build() {
		core.memclean(data);
	}
	public virtual void set(int color, int pos) {
		if(pos >= 512) return;
		data[pos] = color;
	}
}

public class DeepBoard : Board { /* Here it is bulgy COLD data */
	public override void set(int color, int pos) {
		if(pos >= 512) return;
		data[pos] = color+1;
	}
}
```

I think here we can do something crazy,

```
	board.temper(DeepBoard);
	board.set(4,9);
```

The above code may override the _set()_ method runtime.


