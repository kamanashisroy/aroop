
using aroop;

class MainClass : Replicable {
	public static int main() {
		Queue<MainClass> q = Queue<MainClass>();
		q.enqueue(new MainClass());
		q.dequeue();
		q.destroy();
		return 0;
	}
}
