
using aroop;

internal class Orchard : Replicable {
	ArrayList<xtring> fruits;
	int count;
	public Orchard() {
		dump();
		fruits = ArrayList<xtring>();
		count = 0;
		dump();
	}

	~Orchrad() {
		fruits.destroy();
	}

	public void add(xtring fruit) {
		fruits[count++] = fruit;
		dump();
	}
	public int dump() {
		core.memory_profiler_dump((contentLine) => {
			contentLine.zero_terminate();
			print("\n%s\n", contentLine.to_string());
			return 0;
		});
		return 0;
	}
}

class MainClass : Replicable {
	static int mainInternal() {
		Orchard x = new Orchard();
		xtring mango = new xtring.set_static_string("Mango");
		x.add(mango);
		return 0;
	}
	public static int main() {
		int grasped = 0;
		int really_allocated = 0;
		//core.memory_profiler_get_unsafe(&grasped,&really_allocated);
		//print("really allocated:%d,grasped:%d", grasped, really_allocated);
		mainInternal();
		//core.memory_profiler_get_unsafe(&grasped,&really_allocated);
		//print("really allocated:%d,grasped:%d", grasped, really_allocated);
		return 0;
	}
}
