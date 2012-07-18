/*
 * This file part of aroop.
 *
 * Copyright (C) 2012  Kamanashis Roy
 *
 * Aroop is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MiniIM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Aroop.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Created on: Jun 29, 2011
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */



class Animal: aroop.God {
	public virtual aroop.txt voice() {
		return aroop.txt.create_static("Hello world");
	}
	public aroop.txt describe() {
		return aroop.txt.create_static("Time is tiny, women are many.");
	}
}

class Goat : Animal {
	public override aroop.txt voice() {
		return aroop.txt.create_static("maahamaahamaahalo");
	}
}


int main() {
	Animal? an = null;
	an = new Goat();

	aroop.God.pray(an.voice(), aroop.pray.DESCRIBE);
	return 0;
}
