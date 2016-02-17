#!/bin/bash -x

# リクエスト数
req=5000
# Stubby4j の起動待ち時間
time4boot=2
# stubby4j の jar
stubby4j=stubby4j-3.3.0.jar
# 結果ファイル名
result_tsv=perf.tsv

if [ ! -f ./stubby4j-3.3.0.jar ]; then
    curl -L -O http://search.maven.org/remotecontent?filepath=by/stub/stubby4j/3.3.0/stubby4j-3.3.0.jar
fi

# ファイルディスクリプタ数を変更
ulimit -n 8192
# 結果ファイルをクリア
: > $result_tsv

# concurrency でループ
for c in 1 2 5 10 20 50 100; do
    # stubby4j は都度立ち上げる
    java -jar stubby4j-3.3.0.jar -d routes.yaml &
    PID=$!

    # stubby4j の起動時間を確保
    sleep $time4boot

    # 実行
    ab -n $req -c $c -r -q 'http://127.0.0.1:8882/hello-world' | awk -v concurrency="$c" '/across all concurrent requests/ { print concurrency "\t" $4 }' >> $result_tsv

    # stubby4j を kill
    kill $PID

    sleep 10
done

# グラフ作成
gnuplot perf.plt
