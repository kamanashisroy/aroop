

# enter all the directories and make them

DIRS=$(subst Makefile,,$(wildcard *_test))
TARGETS=$(subst _test,.all,$(DIRS))
CTARGETS=$(subst _test,.clean,$(DIRS))

all:$(TARGETS)

%.all:%_test
	$(MAKE) -C $^ all
	touch $@

%.clean:%_test
	$(MAKE) -C $^ clean
	touch $@

clean:$(CTARGETS)
	$(RM) -f *.clean *.all

