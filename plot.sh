#! /bin/bash



# specify a folder
# e.g. data1/

cd "$1/graphs"

for i in $(seq 1 3);
do
    #selected render modus
    files=( $(find *txt | grep -e "-$i-[0-3][0-9]-") )

    for j in $(seq 1 5);
    do
        # echo ${files[(( $j - 1 ))]}
        quarts=($(grep "Quartile:" "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' ))
        mean=($(grep "Mean:" "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' ))
        # storing (vulkan q1, m1, q2,) (gl  q3, m2, q4)
        echo "${quarts[0]} ${mean[0]} ${quarts[1]}  ${quarts[2]} ${mean[1]} ${quarts[3]}" >> "../g-data-$i.txt"
    done
done
