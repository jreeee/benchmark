#! /bin/bash

BASE_DIR="$HOME/git/plamure"
WORKING_DIR="$BASE_DIR/install/bin"
MODEL_1="assets/Modell_Ruine.bvh"
MODEL_2="assets/Schiefer_Turm_part_200M_00001_knobi.bvh"
MODEL_3="assets/statue.bvh"
MODEL_4="assets/Schulgebaeude.bvh"
BENCH_BASE_DIR="$HOME/git/benchmark"
BENCH_LOGS="$BENCH_BASE_DIR/logs"
BENCH_DATA="$BENCH_BASE_DIR/data"
BENCH_GRAPHS="$BENCH_BASE_DIR/graphs"
BENCH_TMP="$BENCH_BASE_DIR/tmp"

TEST_START=500 
TEST_DURATION=5000
UPLOAD_BUDGET=300
RENDER_BUDGET=300

rebuild () {
    cd "$BASE_DIR"
    make build-vk -j RELEASE=y
    make build-gl -j RELEASE=y
    echo "rebuilt vk and gl versions in Release mode"
}

check-lc() {
    num=0
    # first calculate the total frames needed, then add complation output buffer
    # the +50 is to avoid the initial prints
    full_dur=$(echo "($TEST_DURATION + $TEST_START) + 50" | bc)
    while [ $num -le $full_dur ]
    do
        sleep 2
        num=$(wc -l "$1" | cut -d" " -f1)
        echo "[info][$2]: $num from $full_dur intervals rendered"
    done
}

render-vk () {
    cd "$WORKING_DIR"
    logfile="$BENCH_LOGS/vk-$2.log"
    ./unity_dummy_vk --upload_budget $UPLOAD_BUDGET --render_budget $RENDER_BUDGET ../../$1 >> $logfile & check-lc $logfile vk
    pkill unity_dummy_vk
}

render-gl () {
    cd "$WORKING_DIR"
    logfile="$BENCH_LOGS/gl-$2.log"
    ./unity_dummy --upload_budget $UPLOAD_BUDGET --render_budget $RENDER_BUDGET ../../$1 >> $logfile & check-lc $logfile gl
    pkill unity_dummy
}

strip-data () {

    vktmp="$BENCH_TMP/vk-$1.tmp"
    cp "$BENCH_LOGS/vk-$1.log" "$vktmp"
    sed -i '1,/^VK.*/d' "$vktmp"
    gltmp="$BENCH_TMP/gl-$1.tmp"
    cp "$BENCH_LOGS/gl-$1.log" "$gltmp"
    sed -i '1,/^GL.*/d' "$gltmp"
    # for extracting ms
    #it=$TEST_START
    # it_end=$(echo "$TEST_DURATION + $TEST_START" | bc)
    # while [ $it -lt $it_end ]
    # do
    #     echo -e $(echo "($it - $TEST_START)" | bc -l)\\t$(cut -d$'\n' $vktmp -f $it | cut -d " " -f 2)  >> "$BENCH_DATA/ms-$1"
    #     # alternative
    #     # echo -e $(echo "($it - $TEST_START) * 10" | bc -l\\t$(cut -d$'\n' $vktmp -f $it | cut -d " " -f 11) >> "$BENCH_DATA/fps-$1"
    #     ((it++))
    # done
    # echo -e "\n\n" >> "$BENCH_DATA/ms-$1"
    
    # it=$TEST_START
    # while [ $it -lt $it_end ]
    # do
    #     echo -e $(echo "($it - $TEST_START)" | bc -l)\\t$(cut -d$'\n' $gltmp -f $it | cut -d " " -f 2) >> "$BENCH_DATA/ms-$1"
    #     # alternative
    #     # echo -e $(echo "($it - $TEST_START) * 10" | bc -l\\t$(cut -d$'\n' $gltmp -f $it | cut -d " " -f 11) >> "$BENCH_DATA/fps-$1"
    #     ((it++))
    # done
    # # optional for fps
    # # sed -i 's/(//g' "$BENCH_DATA/fps-$1"

}

graph-data () {
    # todo grab data from the info and transfer it here
    graph_file="$BENCH_TMP/graph-$1.dat"
    info_file="$BENCH_LOGS/info-$1.log"
    cp "$BENCH_GRAPHS/template-hist.dat" "$graph_file"
    sed -i 's/FILENAME/'$1'/g' "$graph_file"
    sed -i 's/TITLE/'$(cat $info_file)'/g' "$graph_file"
    cd "$BENCH_BASE_DIR"
    gnuplot -p "$graph_file"
} 

bench-variants () {
    loginfo="$BENCH_LOGS/info-$2.log"
    echo "run: $2 model: $1 | UB: $UPLOAD_BUDGET RB: $RENDER_BUDGET TS: $TEST_START TD: $TEST_DURATION" >> $loginfo
    cat $loginfo
    # ------------------------
    echo "[info] starting vk run"
    render-vk $1 $2
    # ------------------------
    echo "[info] let GPU cool down"
    sleep 5
    echo "[info] starting gl run"
    render-gl $1 $2
    # ------------------------
    echo "[info] both runs have finished, processing data"
    strip-data $log_stamp
    graph-data $log_stamp
}


# rebuild
main () {
    log_stamp=$(date +%m-%d-%H-%M-%S)
    bench-variants $MODEL_1 $log_stamp
    log_stamp=$(date +%m-%d-%H-%M-%S)
    bench-variants $MODEL_2 $log_stamp
    log_stamp=$(date +%m-%d-%H-%M-%S)
    bench-variants $MODEL_3 $log_stamp
    log_stamp=$(date +%m-%d-%H-%M-%S)
    bench-variants $MODEL_4 $log_stamp
}

rebuild
main
