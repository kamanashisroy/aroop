

# enter all the directories and make them

DIRS=$(subst Makefile,,$(wildcard *_test))
TARGETS=$(subst _test,.all,$(DIRS))
CTARGETS=$(subst _test,.clean,$(DIRS))

all:$(TARGETS)

%.all:%_test/Makefile
	$(MAKE) -C $(subst Makefile,,$^) all
	touch $@

%.all:%_test
	$(MAKE) -f ../../arooprules.mk -C $^ all
	touch $@

%.clean:%_test
	$(MAKE) -f ../../arooprules.mk -C $^ clean
	touch $@

%.clean:%_test/Makefile
	$(MAKE) -C $(subst Makefile,,$^) clean
	touch $@

clean:$(CTARGETS)
	$(RM) -f *.clean *.all

