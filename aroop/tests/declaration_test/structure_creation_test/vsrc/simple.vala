
using aroop;

internal struct Point {
	int x;
	int y;
	public Point(int ax, int ay) {
		x = ax;
		y = ay;
	}
	public int getX() {
		return x;
	}
	public int getY() {
		return y;
	}
}

class MainClass : Replicable {
	public static int main() {
		Point pt = Point(5,10);
		pt.getX();
		return 0;
	}
}
