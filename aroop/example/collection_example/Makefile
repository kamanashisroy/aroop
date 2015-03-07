

# enter all the directories and make them

DIRS=$(subst Makefile,,$(wildcard *_example))
TARGETS=$(subst _example,.all,$(DIRS))
CTARGETS=$(subst _example,.clean,$(DIRS))

all:$(TARGETS)

%.all:%_example/Makefile
	$(MAKE) -C $(subst Makefile,,$^) all
	touch $@

%.all:%_example
	$(MAKE) -f ../../arooprules.mk -C $^ all
	touch $@

%.clean:%_example/Makefile
	$(MAKE) -C $(subst Makefile,,$^) clean
	touch $@

%.clean:%_example
	$(MAKE) -f ../../arooprules.mk -C $^ clean
	touch $@

clean:$(CTARGETS)
	$(RM) -f *.clean *.all

