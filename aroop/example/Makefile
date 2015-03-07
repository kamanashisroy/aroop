

# enter all the directories and make them

DIRS=$(subst Makefile,,$(wildcard *_example))
TARGETS=$(subst _example,.all,$(DIRS))
CTARGETS=$(subst _example,.clean,$(DIRS))

all:$(TARGETS)

%.all:%_example
	$(MAKE) -C $^ all
	touch $@

%.clean:%_example
	$(MAKE) -C $^ clean
	touch $@

clean:$(CTARGETS)
	$(RM) -f *.clean *.all

