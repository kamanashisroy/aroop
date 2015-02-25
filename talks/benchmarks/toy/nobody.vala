/* The Computer Language Benchmarks Game
 * http://benchmarksgame.alioth.debian.org/
 *
 * contributed by Christoph Bauer
 *  
 */

using aroop;


public class Nbody {
	enum config {
		NUMBER_OF_BODY = 5,
	}
	struct Planet {
		double x;
		double y;
		double z;
		double vx;
		double vy;
		double vz;
		double mass;

		Planet(double gx, double gy, double dz
			, double gvx, double gvy, double gvz, double gmass) {
			x = gx;y = gy; z = gy;
			vx = gvx;vy = gvy; vz = gvy;
			mass = gmass;
		}
	}
	static double PI;
	static double SOLAR_MASS;
	static double DAYS_PER_YEAR;

	static void advance(Planet bodies[], double dt)
	{
		int i, j;

		for (i = 0; i < config.NUMBER_OF_BODY; i++) {
			Planet *b = &(bodies[i]);
			for (j = i + 1; j < config.NUMBER_OF_BODY; j++) {
				Planet *b2 = &(bodies[j]);
				double dx = b.x - b2.x;
				double dy = b.y - b2.y;
				double dz = b.z - b2.z;
				double distance = sqrt(dx * dx + dy * dy + dz * dz);
				double mag = dt / (distance * distance * distance);
				b.vx -= dx * b2.mass * mag;
				b.vy -= dy * b2.mass * mag;
				b.vz -= dz * b2.mass * mag;
				b2.vx += dx * b.mass * mag;
				b2.vy += dy * b.mass * mag;
				b2.vz += dz * b.mass * mag;
			}
		}
		for (i = 0; i < config.NUMBER_OF_BODY; i++) {
			Planet*b = &(bodies[i]);
			b.x += dt * b.vx;
			b.y += dt * b.vy;
			b.z += dt * b.vz;
		}
	}

	static double energy(Planet bodies[])
	{
		double e;
		int i, j;

		e = 0.0;
		for (i = 0; i < config.NUMBER_OF_BODY; i++) {
			Planet * b = &(bodies[i]);
			e += 0.5 * b.mass * (b.vx * b.vx + b.vy * b.vy + b.vz * b.vz);
			for (j = i + 1; j < config.NUMBER_OF_BODY; j++) {
				Planet * b2 = &(bodies[j]);
				double dx = b.x - b2.x;
				double dy = b.y - b2.y;
				double dz = b.z - b2.z;
				double distance = sqrt(dx * dx + dy * dy + dz * dz);
				e -= (b.mass * b2.mass) / distance;
			}
		}
		return e;
	}

	static void offset_momentum(Planet bodies[])
	{
		double px = 0.0, py = 0.0, pz = 0.0;
		int i;
		for (i = 0; i < config.NUMBER_OF_BODY; i++) {
			px += bodies[i].vx * bodies[i].mass;
			py += bodies[i].vy * bodies[i].mass;
			pz += bodies[i].vz * bodies[i].mass;
		}
		bodies[0].vx = - px / SOLAR_MASS;
		bodies[0].vy = - py / SOLAR_MASS;
		bodies[0].vz = - pz / SOLAR_MASS;
	}


	//public static int main(int argc, string argv[])
	public static int main()
	{
		//int argc = 0;
		//string argc[] = null;
		//extring numberstr = extring.set_string(argv[1]);
		//int n = numberstr.to_int();
		int n = 10;
		int i;
		PI = 3.141592653589793;
		SOLAR_MASS = 4*PI*PI;
		DAYS_PER_YEAR = 365.24;
		Planet bodies[config.NUMBER_OF_BODY];
		bodies[0] = Planet(0, 0, 0, 0, 0, 0, SOLAR_MASS); // Sun
		bodies[1] = Planet( // Jupitar
			4.84143144246472090e+00,
			-1.16032004402742839e+00,
			-1.03622044471123109e-01,
			1.66007664274403694e-03 * DAYS_PER_YEAR,
			7.69901118419740425e-03 * DAYS_PER_YEAR,
			-6.90460016972063023e-05 * DAYS_PER_YEAR,
			9.54791938424326609e-04 * SOLAR_MASS
		);
		bodies[2] = Planet( // Saturn
			8.34336671824457987e+00,
			4.12479856412430479e+00,
			-4.03523417114321381e-01,
			-2.76742510726862411e-03 * DAYS_PER_YEAR,
			4.99852801234917238e-03 * DAYS_PER_YEAR,
			2.30417297573763929e-05 * DAYS_PER_YEAR,
			2.85885980666130812e-04 * SOLAR_MASS
		);
		bodies[3] = Planet( // Uranus
			1.28943695621391310e+01,
			-1.51111514016986312e+01,
			-2.23307578892655734e-01,
			2.96460137564761618e-03 * DAYS_PER_YEAR,
			2.37847173959480950e-03 * DAYS_PER_YEAR,
			-2.96589568540237556e-05 * DAYS_PER_YEAR,
			4.36624404335156298e-05 * SOLAR_MASS
		);
		bodies[4] = Planet( // Neptune
			1.53796971148509165e+01,
			-2.59193146099879641e+01,
			1.79258772950371181e-01,
			2.68067772490389322e-03 * DAYS_PER_YEAR,
			1.62824170038242295e-03 * DAYS_PER_YEAR,
			-9.51592254519715870e-05 * DAYS_PER_YEAR,
			5.15138902046611451e-05 * SOLAR_MASS
		);
		offset_momentum(bodies);
		print("%.9f\n", energy(bodies));
		for (i = 1; i <= n; i++)
			advance(bodies, 0.01);
		print("%.9f\n", energy(bodies));
		return 0;
	}

}
