SCHEME = SodaStream

.PHONY: build test lint autocorrect swiftformat swiftlint_autocorrect bootstrap clangformat loc archive

ci: build
ac: autocorrect
autocorrect: swiftformat swiftlint_autocorrect clangformat

lint:
	swiftlint --strict

swiftformat:
	git ls-files '*.swift' -z | xargs -0 swiftformat --commas inline

swiftlint_autocorrect:
	swiftlint autocorrect

clangformat:
	git ls-files '*.h' '*.m' -z | xargs -0 clang-format -style=file -i

archive:
	carthage build --no-skip-current
	carthage archive SodaStream

build:
	xcodebuild build \
		-alltargets \
		-configuration Debug

bootstrap:
	carthage bootstrap

test:
	xcodebuild test \
		-alltargets \
		-configuration Debug \
		-scheme $(SCHEME)

loc:
	cloc --vcs=git
