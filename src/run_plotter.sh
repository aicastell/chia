#!/bin/bash

cd ${CHIA_INSTALL_DIR}
source ./activate
sleep ${PLOT_ID}h
chia plots create -k ${PLOT_K} -b ${PLOT_B} -e -r ${PLOT_R} -u ${PLOT_U} -n ${PLOT_N} -t ${PLOT_TMP_DRIVE} -d ${PLOT_END_DRIVE} | tee ${CHIA_LOGS}/chia${PLOT_ID}.log

