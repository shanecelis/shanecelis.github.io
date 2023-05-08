SUBDIRS := content/posts/object-oriented-rust-yuck
define FOREACH
    for DIR in $(SUBDIRS); do \
        $(MAKE) -C $$DIR $(1); \
    done
endef

.PHONY: all
all:
	$(call FOREACH,all)

.PHONY: build
build: all
	zola build

.PHONY: deploy
deploy: build
	cd public && gh-pages

.PHONY: clean
clean:
	$(call FOREACH,clean)

# .PHONY: test
# test:
#	$(call FOREACH,test)
