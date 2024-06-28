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

# frames
TEST_START=500 # should be over 50 to avoid irrelevant stdout
TEST_DURATION=5000
# seconds
SLEEP=20
UPLOAD_BUDGET=512
RENDER_BUDGET=256
RAM_BUDGET=4196

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
    full_dur=$(($TEST_DURATION + $TEST_START))
    num_old=1
    while [ $num -le $full_dur ]
    do
        sleep 2
        num=$(wc -l "$1" | cut -d" " -f1)
        echo "[info][$2]: $num from $full_dur intervals rendered"
        if [ $num == $num_old ]; then
            # if the define is not set
            echo "no more stdout :("
            exit 1
        fi
        num_old=$num
    done
}

render-vk () {
    cd "$WORKING_DIR"
    logfile="$BENCH_LOGS/vk-$2.log"
    ./unity_dummy_vk --upload_budget $UPLOAD_BUDGET --render_budget $RENDER_BUDGET --ram_budget $RAM_BUDGET ../../$1 >> $logfile & check-lc $logfile vk
    if pidof unity_dummy_vk; then
        pkill unity_dummy_vk
    else
        exit 2
    fi
}

render-gl () {
    cd "$WORKING_DIR"
    logfile="$BENCH_LOGS/gl-$2.log"
    ./unity_dummy --upload_budget $UPLOAD_BUDGET --render_budget $RENDER_BUDGET --ram_budget $RAM_BUDGET ../../$1 >> $logfile & check-lc $logfile gl
    if pidof unity_dummy; then
        pkill unity_dummy
    else
        exit 2
    fi
}

graph-data () {

    # stripping files
    fin="$((TEST_START + TEST_DURATION))"
    vktmp="$BENCH_TMP/vk-$1.tmp"    
    tail -n "+$TEST_START" "$BENCH_LOGS/vk-$1.log" | head -n "$((fin - TEST_START + 1))" >> "$vktmp"
    gltmp="$BENCH_TMP/gl-$1.tmp"
    tail -n "+$TEST_START" "$BENCH_LOGS/gl-$1.log" | head -n "$((fin - TEST_START + 1))" >> "$gltmp"

    # todo grab data from the info and transfer it here
    graph_file="$BENCH_TMP/graph-$1.dat"
    info_file="$BENCH_LOGS/info-$1.log"
    cp "$BENCH_GRAPHS/template-bin-hist.dat" "$graph_file"
    sed -i 's/FILENAME/'$1'/g' "$graph_file"
    #sed -i 's/TITLE/'$(cat $info_file)'/g' "$graph_file"
    sed -i 's?INFILE1?vk-'$1'.tmp?g' "$graph_file"
    sed -i 's!INFILE2!gl-'$1'.tmp!g' "$graph_file"
    sed -i 's/TOTAL/'$TEST_DURATION'/g' "$graph_file"

    cd "$BENCH_BASE_DIR"
    #i'd love to save the stats right then and there as well since they get printed to the console
    gnuplot -p "$graph_file"  &> "$BENCH_GRAPHS/stats-$1.txt"
} 

bench-variants () {
    loginfo="$BENCH_LOGS/info-$2.log"
    echo "run: $2 model: $1 | UB: $UPLOAD_BUDGET RB: $RENDER_BUDGET TS: $TEST_START TD: $TEST_DURATION" >> $loginfo
    cat $loginfo
    # ------------------------
    echo "[info] starting vk run"
    render-vk $1 $2
    # ------------------------
    echo "[info] let GPU cool down for $SLEEP seconds"
    sleep $SLEEP
    echo "[info] starting gl run"
    render-gl $1 $2
    # ------------------------
    echo "[info] both runs have finished, processing data"
    graph-data $log_stamp
    echo "[info] let GPU cool down for $SLEEP seconds"
    sleep $SLEEP
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

if [ $# -gt "0" ]; then
    rebuild
fi
main
