

class Animal: God {
	public virtual string sound() {
		return "nothing";
	}
}

class Goat : Animal {
	public override string sound() {
		return "maaa";
	}
}


int main() {
	Animal? an = null;
	an = new Goat();

	print(an.sound());
	return 0;
}
