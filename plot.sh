#! /bin/bash


BENCH_BASE_DIR="$HOME/git/benchmark"
WORKING_DIR="$BENCH_BASE_DIR/$1"
TEMPLATE_DIR="$BENCH_BASE_DIR/graphs"
RESOLUTION=("720" "1080" "1440" "2160" "2880")
FOLDERS=("model1" "model1close" "model2" "model2close" "model3" "model3close" "model4" "model4close")
COMP1="$BENCH_BASE_DIR/plot/comp1/graph-data"

# specify a folder
# e.g. data1/




cd graphs

if [ $# -lt 2 ]; then

    for f in $(seq 0 7);
    do
        cd "$BENCH_BASE_DIR/${FOLDERS[$f]}"

        RES_DIR="$BENCH_BASE_DIR/${FOLDERS[$f]}/result"

        if [ ! -d "$RES_DIR" ]; then
            mkdir "$RES_DIR"
        fi

        cd graphs 

        for i in $(seq 1 3);
        do
            #selected render modus
            files=( $(find *txt | grep -e "-$i-[0-3][0-9]-") )
            file_data="$RES_DIR/g-data-$i.txt"
            file_template="$RES_DIR/g-template-$i.dat"
            file_graph="$BENCH_BASE_DIR/plot/graph-${FOLDERS[$f]}-$i.png"

            echo "" > "$file_data"

            for j in $(seq 1 5);
            do
                # echo ${files[(( $j - 1 ))]}
                # trigger recompute for too high vals? 
                
                mean=($(grep "Mean:" "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' ))
                quarts=($(grep "Quartile:" "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' ))
                # echo "${RESOLUTION[(( $j - 1 ))]} ${quarts[0]} ${mean[0]} ${quarts[1]}  ${quarts[2]} ${mean[1]} ${quarts[3]}" >> "../g-data-$i.txt"
                max=($(grep Max "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' | sed 's/\[.*//g'))
                min=($(grep Min "${files[(( $j - 1 ))]}" | cut -d":" -f 2 | sed 's/ //g' | sed 's/\[.*//g'))
                #echo ${min[@]} ${max[@]}
                # storing format: resolution (vulkan avg, min, max, q1, q2) (gl avg, min, max, q1, q2)  
                echo "${RESOLUTION[(( $j - 1 ))]} ${mean[0]} ${min[0]} ${max[0]} ${quarts[0]} ${quarts[1]}  ${mean[1]} ${min[1]} ${max[1]} ${quarts[2]} ${quarts[3]}" >> "$file_data"

                plotnr=$(( f + 1 ))
                if [ $j -eq 2 ]; then
                    echo "$plotnr vk ${mean[0]} ${min[0]} ${max[0]} ${quarts[0]} ${quarts[1]}" >> "$COMP1/vk-1080-$i.txt"
                    echo "$plotnr gl  ${mean[1]} ${min[1]} ${max[1]} ${quarts[2]} ${quarts[3]}" >> "$COMP1/gl-1080-$i.txt"
                elif [ $j -eq 4 ]; then
                    echo "$plotnr vk ${mean[0]} ${min[0]} ${max[0]} ${quarts[0]} ${quarts[1]}" >> "$COMP1/vk-2160-$i.txt"
                    echo "$plotnr gl  ${mean[1]} ${min[1]} ${max[1]} ${quarts[2]} ${quarts[3]}" >> "$COMP1/gl-2160-$i.txt"
                fi
            done

            if [ $# -eq 0 ]; then

                echo $file_data " " $file_graph
                cp "$TEMPLATE_DIR/template-line-avg-rev.dat" "$file_template"
                sed -i 's!INFILE!'"$file_data"'!g' "$file_template"
                sed -i 's!OUTFILE!'"$file_graph"'!g' "$file_template"

                gnuplot "$file_template"
            fi

        done

    done


elif [ $# -eq 2 ]; then

    cd "$COMP1"
    files=( $(find *txt | cut -d. -f1) )
    for val in "${files[@]}"
    do
        file="g-$val.dat"
        cp "$TEMPLATE_DIR/template-whis.dat" "$file"
        ver=$(echo $val | cut -d- -f1)
        if [[ $ver == "vk" ]]; then
            sed -i 's!COLOR!50BA0909!g' "$file"
        else 
            sed -i 's!COLOR!500909BA!g' "$file"
        fi
        sed -i 's!INFILE!'$val'.txt!g' "$file"
        sed -i 's!OUTFILE!../'$val'.png!g' "$file"
        gnuplot "$file"
    done
fi