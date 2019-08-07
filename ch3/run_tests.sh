N=3
for i in $(seq 1 $N); do
    perl 3_1.pl test/object$i.txt test/object$i.out
done

for i in $(seq 1 $N); do
    echo "Test Diff #$i"
    echo "--------------------------------------------------------------------------------"
    echo ""
    diff test/object$i.txt test/object$i.out
    echo ""
done
