# Just a simple script until code is refactored

perl ch4/4_1.pl test/data_4_2/obj1                                       test/data_4_2/obj1_out
perl ch4/4_1.pl test/data_4_2/obj2                                       test/data_4_2/obj2_out
perl ch4/4_1.pl test/data_4_2/obj3                                       test/data_4_2/obj3_out
perl ch4/4_1.pl test/data_4_2/obj1 test/data_4_2/obj2                    test/data_4_2/obj1_obj2_out
perl ch4/4_1.pl test/data_4_2/obj1 test/data_4_2/obj3                    test/data_4_2/obj1_obj3_out
perl ch4/4_1.pl test/data_4_2/obj2 test/data_4_2/obj3                    test/data_4_2/obj2_obj3_out
perl ch4/4_1.pl test/data_4_2/obj1 test/data_4_2/obj2 test/data_4_2/obj3 test/data_4_2/obj1_obj2_obj3_out

echo_test() {
    echo ================================================================================
    echo "TEST $1"
    echo ''
}

RES=0
echo_test test/data_4_2/obj1
diff test/data_4_2/obj1_out           test/data_4_2/obj1_expected           || RES+=1
echo_test test/data_4_2/obj2
diff test/data_4_2/obj2_out           test/data_4_2/obj2_expected           || RES+=1
echo_test test/data_4_2/obj3
diff test/data_4_2/obj3_out           test/data_4_2/obj3_expected           || RES+=1
echo_test test/data_4_2/obj1_obj2
diff test/data_4_2/obj1_obj2_out      test/data_4_2/obj1_obj2_expected      || RES+=1
echo_test test/data_4_2/obj1_obj3
diff test/data_4_2/obj1_obj3_out      test/data_4_2/obj1_obj3_expected      || RES+=1
echo_test test/data_4_2/obj2_obj3
diff test/data_4_2/obj2_obj3_out      test/data_4_2/obj2_obj3_expected      || RES+=1
echo_test test/data_4_2/obj1_obj2_obj3
diff test/data_4_2/obj1_obj2_obj3_out test/data_4_2/obj1_obj2_obj3_expected || RES+=1

rm test/data_4_2/*_out
exit $RES
