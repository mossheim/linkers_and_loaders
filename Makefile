all: test

.PHONY: test
test:
	perl test/test_3.pl
	perl test/test_4.pl
	perl test/test_5_1.pl
	perl test/test_5_23.pl
