SUBDIRS := content/posts/object-oriented-rust-yuck-and-yet
define FOREACH
    for DIR in $(SUBDIRS); do \
        $(MAKE) -C $$DIR $(1); \
    done
endef

.PHONY: all
all:
	$(call FOREACH,all)

.PHONY: watch
watch:
	$(call FOREACH,watch)

.PHONY: build
build: all
	zola build

.PHONY: deploy
deploy: build
	gh-pages -d public --dotfiles

.PHONY: serve
serve: all
	zola serve

.PHONY: clean
clean:
	$(call FOREACH,clean)

# .PHONY: test
# test:
#	$(call FOREACH,test)
