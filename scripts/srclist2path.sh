#!/bin/bash
#echo $(find ../ -name proj.config)
for path in $(find ../ -name proj.config); do 
    declare "$(sed s/PROJNAME=// $path)"="$(dirname ${path})"
done

srclist2paths () {
    srclist=$1
    for srcfile in `eval "cat ${srclist}"`; do
        srcfile=`eval "echo ${srcfile}"`
        if [[ "`basename ${srcfile}`" =~ ".srclist" ]] ; then
            srclist2paths "${srcfile}"
        else 
            if [[ ! "${list}" =~ "${srcfile}" ]] ; then
                list="${list} ${srcfile}"
            fi
        fi    
    done
}



list=""
srclist2paths $@
echo "${list}"