
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

[CCode (cname = "sync_pthread_t", has_destroy_function=false)]
public struct aroop.aroop_pthread {
	[CCode (cname = "aroop_donothing")]
	aroop_pthread();
	[CCode (cname = "sync_pthread_kill")]
	public int kill(int fillme);
	[CCode (cname = "sync_pthread_join")]
	public int join(int fillme);
	[CCode (cname = "sync_pthread_create_background")]
	public int create(int fillme);
}


