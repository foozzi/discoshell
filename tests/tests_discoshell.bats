#!/usr/bin/env bats

setup() {
    export BATS_ENVIRONMENT=1
    export BATS_RESULT_DIR="$HOME/discoshell_test_results"

    TESTS_DIR="$( dirname "$BATS_TEST_FILENAME" )"
    mkdir -p "$HOME/discoshell_test_results" && cd "$HOME/discoshell_test_results"
    echo -e "fz0x1.wtf\nmta-sts.fz0x1.wtf\nwww.fz0x1.wtf" > "subdomains.txt"
    SUBDOMAINS_LIST="$(realpath "subdomains.txt")"
    cd "$TESTS_DIR"
}

teardown() {
    rm -rf "${BATS_RESULT_DIR:?}"
}

@test "Testing single domain with stdout" {
    run ../discoshell.sh -s fz0x1.wtf

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = 'mta-sts.fz0x1.wtf' ] || [ "${lines[6]}" = 'www.fz0x1.wtf' ] || [ "${lines[6]}" = 'fz0x1.wtf' ]
    [ "${lines[7]}" = 'www.fz0x1.wtf' ] || [ "${lines[7]}" = 'fz0x1.wtf' ] || [ "${lines[7]}" = 'mta-sts.fz0x1.wtf' ]
    [ "${lines[8]}" = 'fz0x1.wtf' ] || [ "${lines[8]}" = 'www.fz0x1.wtf' ] || [ "${lines[8]}" = 'mta-sts.fz0x1.wtf' ]
    [ "${lines[9]}" = '[5] Cleaning' ]
    [ "${lines[10]}" = 'Finish' ]
}

@test "Testing domains list with stdout" {
    run ../discoshell.sh -i "$SUBDOMAINS_LIST"

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = 'mta-sts.fz0x1.wtf' ] || [ "${lines[6]}" = 'www.fz0x1.wtf' ] || [ "${lines[6]}" = 'fz0x1.wtf' ]
    [ "${lines[7]}" = 'www.fz0x1.wtf' ] || [ "${lines[7]}" = 'fz0x1.wtf' ] || [ "${lines[7]}" = 'mta-sts.fz0x1.wtf' ]
    [ "${lines[8]}" = 'fz0x1.wtf' ] || [ "${lines[8]}" = 'www.fz0x1.wtf' ] || [ "${lines[8]}" = 'mta-sts.fz0x1.wtf' ]
    [ "${lines[9]}" = '[5] Cleaning' ]
    [ "${lines[10]}" = 'Finish' ]
}

@test "Testing single domain with file output" {
    output_file="$BATS_RESULT_DIR/output.txt"
    run ../discoshell.sh -s fz0x1.wtf -o "output.txt"

    [ "$(sed -n '1p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '1p' "$output_file")" = 'www.fz0x1.wtf' ] || [ "$(sed -n '1p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '2p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '2p' "$output_file")" = 'www.fz0x1.wtf' ] || [ "$(sed -n '2p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '3p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '3p' "$output_file")" = 'www.fz0x1.wtf' ] || [ "$(sed -n '3p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = '[5] Cleaning' ]
    [ "${lines[7]}" = 'Finish' ]
}

@test "Testing domains list with file output" {
    output_file="$BATS_RESULT_DIR/output.txt"
    run ../discoshell.sh -i "$SUBDOMAINS_LIST" -o "output.txt"

    [ "$(sed -n '1p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '1p' "$output_file")" = 'www.fz0x1.wtf' ] || [ "$(sed -n '1p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '2p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '2p' "$output_file")" = 'www.fz0x1.wtf' ] || [ "$(sed -n '2p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '3p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '3p' "$output_file")" = 'www.fz0x1.wtf' ] || [ "$(sed -n '3p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = '[5] Cleaning' ]
    [ "${lines[7]}" = 'Finish' ]
}

@test "Testing single domain with stdout and 'remove-www' option" {
    run ../discoshell.sh -s fz0x1.wtf -rw

    echo "${lines[@]}"

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = 'mta-sts.fz0x1.wtf' ] || [ "${lines[6]}" = 'fz0x1.wtf' ]
    [ "${lines[7]}" = 'fz0x1.wtf' ] || [ "${lines[7]}" = 'mta-sts.fz0x1.wtf' ]
    [ "${lines[8]}" = '[5] Cleaning' ]
    [ "${lines[9]}" = 'Finish' ]
}

@test "Testing domains list with stdout and 'remove-www' option" {
    run ../discoshell.sh -i "$SUBDOMAINS_LIST" -rw

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = 'mta-sts.fz0x1.wtf' ] || [ "${lines[6]}" = 'fz0x1.wtf' ]
    [ "${lines[7]}" = 'fz0x1.wtf' ] || [ "${lines[7]}" = 'mta-sts.fz0x1.wtf' ]
    [ "${lines[8]}" = '[5] Cleaning' ]
    [ "${lines[9]}" = 'Finish' ]
}

@test "Testing single domain with file output and 'remove-www' option" {
    output_file="$BATS_RESULT_DIR/output.txt"
    run ../discoshell.sh -s fz0x1.wtf -o "output.txt" -rw

    [ "$(sed -n '1p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '1p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '2p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '2p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '3p' "$output_file")" = '' ]

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = '[5] Cleaning' ]
    [ "${lines[7]}" = 'Finish' ]
}

@test "Testing domains list with file output and 'remove-www' option" {
    output_file="$BATS_RESULT_DIR/output.txt"
    run ../discoshell.sh -i "$SUBDOMAINS_LIST" -o "output.txt" -rw

    [ "$(sed -n '1p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '1p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '2p' "$output_file")" = 'fz0x1.wtf' ] || [ "$(sed -n '2p' "$output_file")" = 'mta-sts.fz0x1.wtf' ]
    [ "$(sed -n '3p' "$output_file")" = '' ]

    [ "${lines[0]}" = '[1] Starting to gather subdomains.' ]
    [ "${lines[1]}" = '[1.1] subfinder' ]
    [ "${lines[2]}" = '[1.2] amass' ]
    [ "${lines[3]}" = '[2] Sorting' ]
    [ "${lines[4]}" = '[3] Creating a wordlist for subdomains' ]
    [ "${lines[5]}" = '[4] Activity check, filtering wildcard' ]
    [ "${lines[6]}" = '[5] Cleaning' ]
    [ "${lines[7]}" = 'Finish' ]
}
