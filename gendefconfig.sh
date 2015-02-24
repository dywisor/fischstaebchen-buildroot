#!/bin/sh
arches="x86_64"
S="${PWD}/config-fragments"
D="${PWD}/configs"

sp="${S}/fischstaebchen"

set -e
mkdir -p -- "${D}"
for arch in ${arches}; do
   any=

   for tc_variant in tc ext_tc; do
      tbase="${sp}.${tc_variant}_${arch}"

      if [ -e "${tbase}" ]; then

         f="fischstaebchen_x86_64_${tc_variant%tc}defconfig"

         printf '%s\n' "${f}"
         cat "${tbase}" "${sp}.common" > "${D}/${f}"


         f="fischstaebchen_big_x86_64_${tc_variant%tc}defconfig"

         printf '%s\n' "${f}"
         cat "${tbase}" "${sp}.common" "${sp}.big" > "${D}/${f}"

         any=y
      fi
   done


   [ -n "${any}" ] || exit 9
done
