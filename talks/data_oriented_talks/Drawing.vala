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
