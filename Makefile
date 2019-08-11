all: test

.PHONY: test
test:
	perl test/test_3_1.pl
	test/test_4_1.sh
