

class Animal: God {
	public virtual aroop.txt sound() {
		return aroop.txt.create_static("nothing");
	}
}

class Goat : Animal {
	public override aroop.txt sound() {
		var out = aroop.txt.create_static("maa");
		return out;
		//return new aroop.txt("maa", 3, null);
	}
}


int main() {
	Animal? an = null;
	an = new Goat();

	print(an.sound().to_string());
	return 0;
}
