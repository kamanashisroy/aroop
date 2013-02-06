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
 *  Created on: Jul 15, 2012
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */
using aroop;

public abstract class aroop.Spindle : Replicable {
	public Spindle() {
	}
	protected abstract int start(Propeller?plr);
	protected abstract int step();
	public abstract int cancel();
}

[CCode (cname = "TODO_IT_IS_A_THREAD")]
public abstract class aroop.Propeller : Spindle {
	protected Queue<Replicable> msgs; // message queue
	protected bool cancelled;
	public abstract uint get_id();
	protected abstract void run();
	[CCode (cname = "TODO_HALT_STEPPING")]
	public int halt_stepping();
	[CCode (cname = "TODO_START_A_THREAD")]
	//public virtual int start();
	
	public Propeller();/* {
		msgs = new Queue((uchar)get_id());
	}*/
	
	~Propeller() {
		msgs.destroy();
	}
}
