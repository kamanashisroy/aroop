
[CCode (cname = "sync_mutex_t", has_destroy_function=true, destroy_function="sync_mutex_destroy")]
public struct aroop.aroop_mutex {
	[CCode (cname = "sync_mutex_init")]
	aroop_mutex();
	[CCode (cname = "sync_mutex_lock")]
	public int lockup();
	[CCode (cname = "sync_mutex_unlock")]
	public int unlock();
	[CCode (cname = "AVOID_DEAD_LOCK")]
	public int sleepy_trylock();
	[CCode (cname = "sync_mutex_destroy")]
	public int destroy();
}

[CCode (cname = "aroop_pthread_t", has_destroy_function=false)]
public struct aroop.aroop_pthread {
	[CCode (cname = "aroop_donothing")]
	public aroop_pthread();
	[CCode (cname = "aroop_pthread_kill")]
	public int kill(int fillme);
	[CCode (cname = "aroop_pthread_join")]
	public int join(int fillme);
	[CCode (cname = "aroop_pthread_create_background")]
	public int create_and_go(int fillme);
}


