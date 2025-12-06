.PHONY: test fix format publish

test:
	dart test

fix:
	dart fix . --apply

format:
	dart format .

publish:
	dart test && dart pub publish
