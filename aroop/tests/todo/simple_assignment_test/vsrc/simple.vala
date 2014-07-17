
using aroop;

internal class Region : Replicable {
	internal Region?subRegion;
	public class Region() {
		subRegion = null;
	}
}

class MainClass : Replicable {
	public static int main() {
		Region r = new Region();
		r.pin();
		r.subRegion = new Region();
		r = r.subRegion;
		r.subRegion = new Region();
		return 0;
	}
}
