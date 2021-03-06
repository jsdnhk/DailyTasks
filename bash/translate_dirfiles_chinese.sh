#!/usr/bin/env bash

set -eu
set -o pipefail

# Purpose: convert textfile/dir name + content to other form of Chinese (zh-cn to zh-tw as default)
# Prequisites:
# 1) opencc
# 2) moreutils

# if want trad to simp chinese, use 't2s.json' instead
readonly conf_opencc='s2t.json'

target_dir="${1}"   # /relative/fullpath of the target dir.

# try use opencc instead
if [ "$#" -ne 1 ]; then
  echo "not correct input num of argument. should input the target directory at 1st param." >&2
  exit -1
elif [ ! -d "${target_dir}" ]; then
  echo "directory [${target_dir}] is not existed" >&2
  exit -2
fi

dir_depth=$(find "${target_dir}" -type d -not -path "*/\.*" | awk -F"/" 'NF > max {max = NF} END {print max}')
for depth in $(seq 1 ${dir_depth}); do
  # for the dir/file name loop, 1)ignore hidden files/dirs, 2)escape space char
  find "${target_dir}" -mindepth ${depth} -maxdepth ${depth} -type d -not -path '*/\.*' | while read subdir; do
    subdir_new="$(echo -n "${subdir}" | opencc -c "${conf_opencc}")"
    if [ ! -e "${subdir_new}" ];then
      mv -f "${subdir}" "${subdir_new}"
    fi
  done
done

find "${target_dir}" -type f -not -path '*/\.*' | while read file; do
  filename_new="$(echo -e "${file}" | opencc -c "${conf_opencc}")"
  if [ ! -e "${filename_new}" ];then
    mv -f "${file}" "${filename_new}"
  fi
  if [[ "$(file "${filename_new}")" =~ 'UTF-8' ]];then
    echo "Translating file [${filename_new}]..."
    opencc -i "${filename_new}" -c "${conf_opencc}" | sponge "${filename_new}"
  fi
done

echo "All the UTF-8 textfiles inside the dir. inside ${target_dir} is converted to Sim.Chinese to Trad.Chinese!"
exit 0
