all: test

.PHONY: test
test:
	perl test/test_3_1.pl
	perl test/test_4_1.pl
	perl test/test_4_2.pl
