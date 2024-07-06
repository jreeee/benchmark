#! /bin/bash


BENCH_BASE_DIR="$HOME/git/benchmark"
WORKING_DIR="$BENCH_BASE_DIR/$1"
RES_DIR="$BENCH_BASE_DIR/$1/result"
TEMPLATE_DIR="$BENCH_BASE_DIR/graphs"
RESOLUTION=("720" "1080" "1440" "2160" "2880")

# specify a folder
# e.g. data1/

cd "$WORKING_DIR"

if [ ! -d "$RES_DIR" ]; then
    mkdir "$RES_DIR"
else 
    rm -rm "$RES_DIR/*"
fi

cd graphs

for i in $(seq 1 3);
do
    #selected render modus
    files=( $(find *txt | grep -e "-$i-[0-3][0-9]-") )

    file_data="$RES_DIR/g-data-$i.txt"
    file_template="$RES_DIR/g-template-$i.dat"
    file_graph="$WORKING_DIR/graph-$i.png"



    for j in $(seq 1 5);
    do
        # echo ${files[(( $j - 1 ))]}
        # trigger recompute for too high vals?
        
        mean=($(grep "Mean:" "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' ))
        #quarts=($(grep "Quartile:" "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' ))
        # echo "${RESOLUTION[(( $j - 1 ))]} ${quarts[0]} ${mean[0]} ${quarts[1]}  ${quarts[2]} ${mean[1]} ${quarts[3]}" >> "../g-data-$i.txt"
        max=($(grep Max "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' | sed 's/\[.*//g'))
        min=($(grep Min "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' | sed 's/\[.*//g'))
        #echo ${min[@]} ${max[@]}
        # storing resolution (vulkan 1, avg, 2,) (gl  1, avg, 2)
        echo "${RESOLUTION[(( $j - 1 ))]} ${min[0]} ${mean[0]} ${max[0]}  ${min[1]} ${mean[1]} ${max[1]}" >> "$file_data"
    done

    echo $file_data " " $file_graph
    cp "$TEMPLATE_DIR/template-line-avg.dat" "$file_template"
    sed -i 's!INFILE!'"$file_data"'!g' "$file_template"
    sed -i 's!OUTFILE!'"$file_graph"'!g' "$file_template"

    gnuplot "$file_template"

done
