#! /bin/bash

USER=chia
TMP_DRIVES="sda"
PLOT_DRIVES="sdb sdc"
CHIA_INSTALL_DIR=/home/${USER}/Documentos/chia-blockchain

PLOT_K_SIZE=32
PLOT_MB_B=4000
PLOT_CPUS_R=4
PLOT_BUCKETS_U=128
PLOT_CHALLENGE_N=16

press_enter()
{
    echo "Press enter to continue"
    read CONT
}

show_menu()
{
    echo "*************************************************"
    echo "CRIPTOBADIA SL"
    echo "Chia controller menu"
    echo "  a. Activate chia environment"
    echo "  d. Deactivate chia environment"
    echo "  k. Set plot parameters"
    echo "  v. Show chia version"
    echo "  1. Start farming"
    echo "  2. Stop farming"
    echo "  3. Setup directories"
    echo "  4. Generate keys"
    echo "  6. Wallet show"
    echo "  7. Verify plots"
    echo "  8. Verify farmer"
    echo "  q. Exit"
    echo "*************************************************"
}

setup_dirs()
{
    mkdir -p /home/${USER}/chialogs
    chmod 777 /home/${USER}/chialogs 

    c=1
    for d in ${TMP_DRIVES}
    do
        if [ -b /dev/${d} ]; then
            echo mkdir -p /media/tmp-${c}
            echo chmod 777 /media/tmp-${c}
            echo mount /dev/${d} /media/tmp-${c}
            c=$((c+1))
        fi
    done

    c=1
    for d in ${PLOT_DRIVES}
    do
        if [ -b /dev/${d} ]; then
            echo mkdir -p /media/plot-${c}
            echo chmod 777 /media/plot-${c}
            echo mount /dev/${d} /media/plot-${c} 
            echo chia plots add -d /media/plot-${c}
            c=$((c+1))
        fi
    done
}

while [ 1 ];
do
    show_menu
    echo -ne "Choose an option: "
    read OPT

    case $OPT in
    a) 
        echo "Activate chia environment"
        cd ${CHIA_INSTALL_DIR}
        source ./activate
        press_enter
        ;;

    d)
        echo "Deactivate chia environment"
        cd ${CHIA_INSTALL_DIR}
        deactivate
        press_enter
        ;;

    k)
        echo "Set plot parameters"
        press_enter
        ;;

    v)
        echo "Show chia version"
        chia version
        press_enter
        ;;

    1)
        echo "Start farming"
        chia start farmer -r
        press_enter
        ;;

    2)
        echo "Stop farming"
        chia stop -d all
        press_enter
        ;;

    3)
        echo "Setup directories"
        setup_dirs
        press_enter
        ;;

    4)
        echo "Generate keys"
        chia init
        chia keys generate
        press_enter
        ;;

    6)
        echo "Wallet show"
        chia wallet show
        press_enter
        ;;

    7)
        echo "Verify plots"
        chia plots check
        press_enter
        ;;

    8)
        echo "Verify farmer"
        chia farm summary
        press_enter
        ;;

    q)
        echo "Option 0 selected"
        exit
        ;;

    *)
        echo Unknown option
        ;;
    esac

done

echo 


