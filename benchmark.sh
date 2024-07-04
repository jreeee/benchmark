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

RESOLUTION_1="--sc_x=1280 --sc_y=720"
RESOLUTION_2="--sc_x=1920 --sc_y=1080"
RESOLUTION_3="--sc_x=2560 --sc_y=1440"
RESOLUTION_4="--sc_x=3840 --sc_y=2160"
RESOLUTION_5="--sc_x=5120 --sc_y=3200"

REN_MODE=1

# frames
TEST_START=500 # should be over 50 to avoid irrelevant stdout
TEST_DURATION=5000
# seconds
SLEEP=10
UPLOAD_BUDGET=1024
RENDER_BUDGET=256 # cant be greater than this atm bc gl refining not using all that is available
RAM_BUDGET=16384

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
        sleep 4
        num=$(wc -l "$1" | cut -d" " -f1)
        echo "[info][$2]: $num from $full_dur frames rendered"
        if [ $num == $num_old ]; then
            # if the define is not set
            echo "no more stdout ?"
            # pkill unity_dummy_vk
            # exit 1
        fi
        num_old=$num
    done
}

render-vk () {
    cd "$WORKING_DIR"
    logfile="$BENCH_LOGS/vk-$2.log"
    case $3 in
        1) resolution="$RESOLUTION_1";;
        2) resolution="$RESOLUTION_2";;
        3) resolution="$RESOLUTION_3";;
        4) resolution="$RESOLUTION_4";;
        5) resolution="$RESOLUTION_5";;
        *) resolution="$RESOLUTION_2";;
    esac
    ./unity_dummy_vk ../../$1 --upload_budget $UPLOAD_BUDGET --render_budget $RENDER_BUDGET --ram_budget $RAM_BUDGET $resolution --render_type=$4 >> $logfile & check-lc $logfile vk
    if pidof unity_dummy_vk; then
        pkill unity_dummy_vk
    else
        exit 2
    fi
    echo "[info][vk] removing impossible frametimes"
    sed -i 's/VK 167271//g' "$logfile"
}

render-gl () {
    cd "$WORKING_DIR"
    logfile="$BENCH_LOGS/gl-$2.log"
    case $3 in
        1) resolution="$RESOLUTION_1";;
        2) resolution="$RESOLUTION_2";;
        3) resolution="$RESOLUTION_3";;
        4) resolution="$RESOLUTION_4";;
        5) resolution="$RESOLUTION_5";;
        *) resolution="$RESOLUTION_2";;
    esac
    ./unity_dummy ../../$1 --upload_budget $UPLOAD_BUDGET --render_budget $RENDER_BUDGET --ram_budget $RAM_BUDGET $resolution --render_type=$4 >> $logfile & check-lc $logfile gl
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
    gnuplot "$graph_file"  &> "$BENCH_GRAPHS/stats-$1.txt"
} 

bench-variants () {
    loginfo="$BENCH_LOGS/info-$2.log"
    echo "run: $2 model: $1 | resolution: $3 render mode: $4 | UB: $UPLOAD_BUDGET RB: $RENDER_BUDGET TS: $TEST_START TD: $TEST_DURATION" >> $loginfo
    cat $loginfo
    # ------------------------
    echo "[info] starting vk run"
    render-vk $1 $2 $3 $4
    # ------------------------
    echo "[info] let GPU cool down for $SLEEP seconds"
    sleep $SLEEP
    echo "[info] starting gl run"
    render-gl $1 $2 $3 $4
    # ------------------------
    echo "[info] both runs have finished, processing data"
    graph-data $log_stamp
    echo "[info] let GPU cool down for $SLEEP seconds"
    sleep $SLEEP
}


main () {
    # MAX=2048
    RUN=1

    for i in $(seq 1 5);
        do

        for j in $(seq 1 3);
        do
            echo "[info] starting run $RUN from $RUNS with $RENDER_BUDGET"
            log_stamp=run$RUN-$i-$j-$(date +%m-%d-%H-%M-%S)_model-1
            bench-variants $MODEL_1 $log_stamp $i $j
            # log_stamp=run$RUN-$i-$j_$(date +%m-%d-%H-%M-%S)_model-2
            # bench-variants $MODEL_2 $log_stamp $i $j
            # log_stamp=run$RUN-$i-$j_$(date +%m-%d-%H-%M-%S)_model-3
            # bench-variants $MODEL_3 $log_stamp $i $j
            # log_stamp=run$RUN-$i-$j_$(date +%m-%d-%H-%M-%S)_model-4
            # bench-variants $MODEL_4 $log_stamp $i $j
            RUN=$((RUN + 1))
        done
    #     
	# # pkill gnuplot_qt
    #     RENDER_BUDGET=$((RENDER_BUDGET * 2))
    done
}

if [ $# -gt "0" ]; then
    rebuild
fi

main
