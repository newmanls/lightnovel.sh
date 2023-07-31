#!/usr/bin/env bash

# Name:         lightnovel.sh
# Description:  A terminal-based lightnovel reader written in Bash.
# Author:       Newman Sanchez (https://github.com/lr-tech)
# Github repo:  https://github.com/lr-tech/lightnovel.sh

version="0.2"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/lightnovel.sh"
dependencies=("curl" "grep" "head" "less" "mkdir" "sed" "tput" "tr" "w3m")

IFS=$'\n'
red="\033[1;31m"
green="\033[1;32m"
blue="\033[1;34m"
white="\033[1;37m"
default="\033[0m"
url='https://innread.com'
history="${cache_dir}/history"
history_lenght=20

print_msg() {
    printf "${blue}::${white} %s${default}\n" "${*}"
}

print_error() {
    printf " ${red}->${default} %s\n" "${*}" >&2
}

print_list_item() {
    printf "${blue}%s${default} %s\n" "[${1}]" "${2}"
}

prompt() {
    printf "${green}==>${white} %s${default}" "${1}" && read -r "${2}"
}

add_to_history() {
    new_entry="${novel_name}|${chapter_num}|${novel_url}|${chapter_url}"

    if [ -s "${history}" ]; then
        old_history="$( grep -v "^${novel_name}|" "${history}" |
            head -n $((history_lenght - 1)))"
        printf "%s\n%s" "${new_entry}" "${old_history}" > "${history}"
    else
        mkdir -p "${cache_dir}"
        printf "%s" "${new_entry}" > "${history}"
    fi
}

load_history_item() {
    IFS='|' read -r novel_name chapter_num novel_url chapter_url < \
        <(sed "${1}q;d" "${history}")
}

check_number_input() {
    local max_num="${1:--1}"
    local input_num="${2:--1}"

    if (( input_num >= 1 )) && (( input_num <= max_num )); then
        return 1
    else
        print_error "Invalid selection"
        return 0
    fi
}

check_download() {
    [ ! "${1}" ] && print_error "Connection refused" && exit 1
}

get_chapter_count() {
    lastest_chapter_url=$(curl -s "${novel_url}" | grep 'lastest_chapter_url' |
        sed 's/^.*content="//;s/">//')

    check_download "${lastest_chapter_url}"

    chapter_count=$(tr -dc '0-9' <<< "${lastest_chapter_url}")
}

get_chapter_prefix() {
    chapter_prefix=$(grep -o '^.*chapter-' <<< "${1}")
}

search_novel() {
    prompt "Search novel: " "searchkey"
    print_msg "Searching for '${searchkey}'..."

    params="searchkey=${searchkey}"
    scraped_results=$(curl -s -d "${params}" "${url}/search/")

    check_download "${scraped_results}"

    scraped_results=$(grep '<h3 class="tit"><a' <<< "${scraped_results}")
    mapfile -t result_titles < \
        <(sed 's/^.*title="//;s/">.*$//' <<< "${scraped_results}")
    mapfile -t result_urls < \
        <(sed 's/^.*href="//;s/".*$//' <<< "${scraped_results}")
    scraped_novel_count="${#result_titles[@]}"

    if [ "${scraped_novel_count}" = "0" ]; then
        print_error "No search results found"
        printf "\n"
        search_novel
    else
        print_msg "Found ${scraped_novel_count} result(s):"
        for ((i = 1; i < scraped_novel_count + 1; i++)); do
            print_list_item "${i}" "${result_titles[${i} - 1]}"
        done
        select_novel
    fi
}

select_novel() {
    if (( scraped_novel_count > 1 )); then
        printf "\n"
        prompt "Select novel (1-${scraped_novel_count}): " "selected_novel_num"
    else
        print_msg "Selected '${result_titles[0]}'"
        selected_novel_num=1
    fi

    if check_number_input "${scraped_novel_count}" "${selected_novel_num}"; then
        select_novel
    else
        novel_url="${url}${result_urls[${selected_novel_num} - 1]}"
        novel_name="${result_titles[${selected_novel_num} - 1]}"
        fetch_chapters
    fi
}

fetch_chapters() {
    print_msg "Fetching chapters..."
    get_chapter_count
    get_chapter_prefix "${lastest_chapter_url}"
    printf "\n"
    select_chapter
}

select_chapter() {
    prompt "Select chapter (1-${chapter_count}): " "chapter_num"

    if check_number_input "${chapter_count}" "${chapter_num}"; then
        printf "\n"
        select_chapter
    else
        chapter_url="${chapter_prefix}${chapter_num}.html"
        retrieve_chapter
    fi
}

retrieve_chapter() {
    print_msg "Retrieving chapter..."
    [ "${chapter_count}" ] || get_chapter_count
    [ "${chapter_prefix}" ] || get_chapter_prefix "${chapter_url}"

    retrieved_chapter="$(curl -s "${chapter_url}" |
        sed -n '/class="chapter-start"/,/class="chapter-end"/p')"

    check_download "${retrieved_chapter}"
    add_to_history
    open_chapter
}

open_chapter() {
    w3m -T text/html -cols "$(tput cols)" <<< "${retrieved_chapter}" |
        ${PAGER:-less}
    print_nav_menu
}

open_next_chapter() {
    if (( chapter_num < chapter_count )); then
        chapter_num=$((chapter_num + 1))
        chapter_url="${chapter_prefix}${chapter_num}.html"
        retrieve_chapter
    fi
}

open_previous_chapter() {
    if (( chapter_num > 1 )); then
        chapter_num=$((chapter_num - 1))
        chapter_url="${chapter_prefix}${chapter_num}.html"
        retrieve_chapter
    fi
}

print_nav_menu() {
    clear
    print_msg "${novel_name} (${chapter_num}/${chapter_count})"
    (( chapter_num < chapter_count )) && print_list_item "N" "Next chapter"
    (( chapter_num > 1 )) && print_list_item "P" "Previous chapter"
    (( chapter_count > 1 )) && print_list_item "C" "Select chapter"
    print_list_item "O" "Reopen current chapter"
    print_list_item "S" "Search another novel"
    print_list_item "H" "Go to home screen"
    print_list_item "Q" "Exit"

    printf "\n"
    prompt "" "user_input"
    clear

    case "${user_input,}" in
        n) (( chapter_num < chapter_count )) && open_next_chapter ;;
        p) (( chapter_num > 1 )) && open_previous_chapter ;;
        c) (( chapter_count > 1 )) && select_chapter ;;
        o) open_chapter ;;
        s) search_novel ;;
        h) print_homescreen ;;
        q) exit 0 ;;
        *) print_nav_menu ;;
    esac
}

print_homescreen() {
    clear
    mapfile -t history_items < \
        <(sed 's/\(.*|[0-9]*\)|.*/\1/;s/|/ - Chapter /g' "${history}")
    history_count="${#history_items[@]}"

    print_msg "Continue reading:"
    for ((i = 1; i < history_count + 1; i++)); do
        print_list_item "${i}" "${history_items[${i} - 1]}"
    done
    printf "\n"
    print_list_item "S" "Search another novel"
    print_list_item "Q" "Exit"
    printf "\n"
    prompt "" "user_input"
    clear

    case "${user_input,}" in
        [1-${history_count}])
            load_history_item "${user_input}"
            retrieve_chapter ;;
        s) search_novel ;;
        q) exit 0 ;;
        *) print_homescreen ;;
    esac
}

print_help() {
    printf "A terminal-based lightnovel reader written in Bash.

USAGE:
  lightnovel.sh [OPTION]

OPTIONS:
  -c, --clear-cache     Clear cache (%s)
  -h, --help            Print this help page
  -l, --last-session    Restore last session
  -V, --version         Print version number
" "${cache_dir}"
}

print_version() {
    printf "lightnovel.sh %s\n" "${version}"
}

clear_cache() {
    prompt "Clear cache? [y/N] " "user_input"

    [ "${user_input,}" = "y" ] && rm -rf "${cache_dir:?}/" &&
        print_msg "Cache successfully cleared"
}

restore_last_session() {
    [ ! -s "${history}" ] && print_error "No history found" && exit 1

    load_history_item 1
    retrieve_chapter
}

check_dependencies() {
    for dependency in "${dependencies[@]}"; do
        [ "$(command -v "${dependency}")" ] || missing_deps+="${dependency} "
    done

    if [ "${missing_deps}" ]; then
        printf "Missing dependencies: %s\n" "${missing_deps}" && exit 1
    fi
}

main() {
    check_dependencies

    case "${1}" in
        '')
            [ -s "${history}" ] && print_homescreen || search_novel ;;
        -c|--clear-cache)
            clear_cache ;;
        -h|--help)
            print_version
            print_help ;;
        -l|--last-session)
            restore_last_session ;;
        -V|--version)
            print_version ;;
        *)
            print_version
            print_help
            exit 1 ;;
    esac
}

main "${@}"
