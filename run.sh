#!/bin/bash

# download NIST
wget -q https://csrc.nist.gov/CSRC/media/Projects/Random-Bit-Generation/documents/sts-2_1_2.zip

# extract NIST
unzip -q sts-2_1_2.zip
rm sts-2_1_2.zip

# rename directory and subdirectory
mv sts-2.1.2/sts-2.1.2/ NIST/

# execute makefile
cd NIST
make &> /dev/null
cd ..

# test array
test=( Frequency BlockFrequency CumulativeSums Runs LongestRun Rank FFT NonOverlappingTemplate OverlappingTemplate Universal ApproximateEntropy RandomExcursions RandomExcursionsVariant Serial LinearComplexity )

# create multiple NIST instances (one for each test)
for i in "${!test[@]}";
do
    cp -R NIST ${test[$i]}
done

# create directory for test logs
mkdir -p logs

for i in "${!test[@]}";
do
(   
    echo "${test[$i]} started @ `date`"
    cd ${test[$i]}/
    
    # create test selection string "0..0 1 0..0"
    if [[ $i != "0" ]]; then
        printf -v beg "%0${i}d" 0
    else
        beg=""
    fi

    let "j = 14 - $i"
    if [[ $j != "0" ]]; then
        printf -v end "%0${j}d" 0
    else
        end=""
    fi

    test_select="${beg}1${end}"
    
    # skip parameter adjustment wherever possible
    param_test=( BlockFrequency NonOverlappingTemplate OverlappingTemplate ApproximateEntropy Serial LinearComplexity)
    param_adj=""
    for tname in ${param_test[@]};
    do
        if [[ ${test[$i]} == $tname ]];
        then
            param_adj="0\n"
        fi
    done

    # run test
    printf "0\n../data.bin\n0\n${test_select}\n${param_adj}100000\n1\n" | ./assess 1000000 > /dev/null
   
    # collect logs
    cd experiments/AlgorithmTesting/
    testdir=${test[$i]}
    cd $testdir
    testdir=${testdir%*/} # remove trailing /
    if [[ -f data1.txt ]];
    then
        for file in data*.txt;
        do
            cp $file "${file/data/$testdir}"
        done
        cp $testdir* ../../../../logs/
    else
        cp results.txt ../../../../logs/$testdir.txt
    fi
    cd ../../../../
    echo "${test[$i]} finished @ `date`"
    rm -R "${test[$i]}"
) &
done

wait

# delete original NIST instance
rm -R NIST

echo "---the end @ `date`---"

