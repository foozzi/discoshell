#!/usr/bin/env bash
#
# Discoshell
#
# © 2023 fz0x1
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions, and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this
#    list of conditions, and the following disclaimer in the documentation and/or
#    other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#
# Contact me for questions and suggestions:
#
# Name: fz0x1
# Email: me@fz0x1.wtf
#
# You can also find the source code of this script and collaborate on GitHub:
# Repository: https://github.com/foozzi/discoshell
#
VERSION="0.1.0b"

# bash settings
trap cleanup INT
shopt -s expand_aliases

# variables
if [[ -n "$BATS_ENVIRONMENT" ]]; then  # tests
    discoshell_results="$BATS_TEST_DIR"
else
    discoshell_results=.discoshell_results
fi
subfinder_output=subfinder.txt
amass_output=amass.txt
alterx_output=generated_subdomains.txt
all_subdomains=subdomains.txt
tmp_subdomains=subdomains_tmp.txt
script_dir="$(pwd)"

set_text_color() {
    if [[ -z "$BATS_ENVIRONMENT" ]]; then  # tests
        tput setaf "$1"
    else
        true
    fi
}

set_bold_text() {
    if [[ -z "$BATS_ENVIRONMENT" ]]; then  # tests
        tput bold
    else
        true
    fi
}

reset_text_format() {
    if [[ -z "$BATS_ENVIRONMENT" ]]; then  # tests
        tput sgr0
    else
        true
    fi
}

function die() {
    set_text_color 1
    echo "Script failed: $1, exiting..."
    reset_text_format
    rm -rf "$discoshell_results"
    exit 1
}

function cleanup() {
    set_text_color 1
    echo "exiting..."
    reset_text_format
    exit 0
}

function usage() {
    echo ""
    set_text_color 62
    set_bold_text
    echo "Discoshell [discovery-shell]"
    reset_text_format
    set_text_color 63
    set_bold_text
    echo "         v.$VERSION"
    reset_text_format
    echo ""
    echo "Simple utility for discovering subdomains and manipulating the results."
    echo ""
    set_bold_text
    echo "usage: $0 --input string --output string "
    reset_text_format
    echo ""
    set_bold_text
    echo "  -i|--input string       input file name"
    reset_text_format
    echo "                          (example: input.txt)"
    set_text_color 2
    echo "                          required if '-s|--single' was not set"
    reset_text_format
    echo ""
    set_bold_text
    echo "  -s|--single string      single domain"
    reset_text_format
    echo "                          (example: site.com)"
    echo "                          note: you have to use it if you want discover just one domain instead a list"
    set_text_color 2
    echo "                          required if '-i|--input' was not set"
    reset_text_format
    echo ""
    set_bold_text
    echo "  -o|--output string      output file name"
    reset_text_format
    echo "                          (example: output.txt)"
    echo "                          note: if not set, output will be in stdout"
    echo ""
    set_bold_text
    echo "  -rw|--remove-www        removing 'www.' from a subdomain string (for ex: www.site.com, default is disabled)"
    reset_text_format
    echo "                          not required"
    echo ""
    echo ""
    set_bold_text
    echo "  -h|--help               this message"
    reset_text_format
    echo ""
}

# setting alias for `sed`
# BSD version requires specifying a backup file. for ex: `sed -i "" ...`
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias sed_alias='sed -i ""'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    alias sed_alias='sed -i'
else
    die "Unsupported operating system: $OSTYPE"
fi

# checking installed tools
tools=("amass" "subfinder" "alterx" "massdns" "puredns")
for tool in "${tools[@]}"; do
    if [ ! -x "$(command -v "$tool")" ]; then
        die "$tool is not installed"
    fi
done
# amass version checking
amass_version=$(amass --version 2>&1)
if [[ "$amass_version" != "v3"* ]]; then
  die "Discoshell supports only amass v3"
fi

# parsing of arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -h|--help)
            usage
            exit 0
            ;;
        -i|--input)
            if [[ -z "$2" ]]; then
                die "Missing argument for $key"
            fi
            input="$2"
            shift 2
            ;;
        -s|--single)
            if [[ -z "$2" ]]; then
                die "Missing argument for $key"
            fi
            single="$2"
            shift 2
            ;;
        -o|--output)
            if [[ -z "$2" ]]; then
                die "Missing argument for $key"
            fi
            output="$2"
            shift 2
            ;;
        -rw|--remove-www)
            remove_www=1
            shift
            ;;
        *)
            break
            ;;
    esac
done


# checking the arguments
if [[ -z "$input" ]] && [[ -z "$single" ]]; then
    usage
    die "Missing parameters '--input' or '--single'"
elif [[ -n "$input" ]] && [[ -n "$single" ]]; then
    usage
    die "You can not set 'input' and 'single' options at the same time"
fi

if [[ -z "$single" ]]; then
    if [ ! -e "$input" ]; then
        die "File '$input' not found"
    fi
    filename="$(realpath "$input")"
fi

# creating tmp dir
cd "$HOME" || exit
mkdir -p "$discoshell_results" && cd "$discoshell_results" || exit
tmp_dir=$(pwd)

# removing 'www.site.ru' links
function rw() {
    if [[ -n "$remove_www" ]]; then
        sed_alias /^www\./d "$1"
    fi
}

# TOOLS
# subfinder
function subfinder_cmd() {
    if [[ -z "$3" ]]; then
        subfinder -silent -dL "$1" -all -o "$2" > /dev/null
    else
        subfinder -silent -d "$1" -all -o "$2" > /dev/null
    fi
}
# amass
function amass_cmd() {
    if [[ -z "$3" ]]; then
        amass enum -silent -df "$1" -passive -o "$2" > /dev/null
    else
        amass enum -silent -d "$1" -passive -o "$2" > /dev/null
    fi
}
# puredns
function puredns_cmd() {
    if  [[ -z "$2" ]]; then
        puredns resolve "$1" --trusted-only 2> /dev/null
    else
        puredns resolve "$1" --trusted-only --write "$2" &> /dev/null
    fi
}
# alterx
function alterx_cmd() {
    # I decided these permutations might be enough
    params=(
        "{{word}}-{{sub}}.{{suffix}}"
        "{{sub}}-{{word}}.{{suffix}}"
        "{{word}}.{{sub}}.{{suffix}}"
        "{{sub}}.{{word}}.{{suffix}}"
        "{{sub}}{{number}}.{{suffix}}"
    )
    for param in "${params[@]}"; do
        alterx -enrich -p "$param" -silent < "$1"
    done | sort -u > "$2"
}


set_text_color 4
echo "[1] Starting to gather subdomains."
reset_text_format


set_text_color 6
echo "[1.1] subfinder"
reset_text_format
if [[ -z "$BATS_ENVIRONMENT" ]]; then  # tests
    if [[ -n "$single" ]]; then
        subfinder_cmd "$single" "$subfinder_output" 1
    else
        subfinder_cmd "$filename" "$subfinder_output"
    fi
fi


set_text_color 6
echo "[1.2] amass"
reset_text_format
if [[ -z "$BATS_ENVIRONMENT" ]]; then  # tests
    if [[ -n "$single" ]]; then
        amass_cmd "$single" "$amass_output" 1
    else
        amass_cmd "$filename" "$amass_output"
    fi
fi


set_text_color 4
echo "[2] Sorting"
reset_text_format
if [[ -z "$BATS_ENVIRONMENT" ]]; then  # tests
    sort -u "$subfinder_output" "$amass_output" > "$all_subdomains"
fi

rw "$all_subdomains"

puredns_cmd "$all_subdomains" "$tmp_subdomains" # filtering only the live subdomains before generating a wordlist
if [[ ! -s "$tmp_subdomains" ]]; then
    die "Nothing found"
fi


set_text_color 4
echo "[3] Creating a wordlist for subdomains"
reset_text_format
alterx_cmd "$tmp_subdomains" "$alterx_output"

rw "$alterx_output"

sort -u "$tmp_subdomains" "$alterx_output" > "$all_subdomains"

set_text_color 4
echo "[4] Activity check, filtering wildcard"
reset_text_format
if [[ -z "$output" ]]; then
    set_text_color 2
    puredns_cmd "$all_subdomains"
    reset_text_format
else
    if [[ -z "$BATS_ENVIRONMENT" ]]; then # tests
        puredns_cmd "$all_subdomains" "$script_dir/$output"
    else
        puredns_cmd "$all_subdomains" "$output"
    fi
fi


set_text_color 4
echo "[5] Cleaning"
reset_text_format
if [[ -z "$BATS_ENVIRONMENT" ]]; then  # tests
    rm -rf "$tmp_dir"
fi


set_text_color 2
echo "Finish"
reset_text_format
