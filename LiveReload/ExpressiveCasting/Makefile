.PHONY: help release lint commit push

package := $(notdir $(abspath .))
podspec := $(package).podspec
version := $(shell perl -ne 'print $$1 if /version\s*=\s*"(\d+\.\d+\.\d+)"/' $(podspec))

help:
	@perl -ne 'print(substr($$_, 3)) if /^## /' $(lastword $(MAKEFILE_LIST))

# to skip substeps, use e.g. make release -o tag -o push
release: version commit tag push
	pod trunk push

tag:
	git tag -a -m "Release $(version)" $(TAGFLAGS) $(version)

undo-tag:
	-git tag -d $(version)
	git push origin :refs/tags/$(version)

push:
	git push --follow-tags $(PUSHFLAGS)

lint:
	pod lib lint

commit:
	-test -n "$$(git status --porcelain)" && git add -A && git commit -vem "Release $(version)"
	test -z "$$(git status --porcelain)"

version:
	@echo $(package) v$(version)
