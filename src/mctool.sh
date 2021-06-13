#! /bin/bash
# CRIPTOBADIA SLU
# contacto@criptobadia.es
#
# Tool to make your life easier working with Chia coin
# vers: 0.0.1
#

USER=aicastell
CHIA_INSTALL_DIR=/home/${USER}/Descargas/chia-blockchain
CHIA_LOGS=/home/${USER}/chialogs

# apt-get dependencies
APT_DEPENDS="git vim make gcc parted"

# Plotter process number
PLOT_ID=0

# Default plot params
PLOT_K=32
PLOT_B=4000
PLOT_R=4
PLOT_U=128
PLOT_N=16

PLOT_TMP_DRIVE=/media/tmp-01
PLOT_END_DRIVE=/media/plot-01

press_enter()
{
    echo "Press ENTER to continue"
    read CONT
}

show_menu()
{
    echo "*************************************************"
    echo "CRIPTOBADIA SLU"
    echo "Chia controller menu"
    echo "  d. See devices and partitions available"
    echo "  p. Setup partition (sdX)"
    echo "  k. Set plotter parameters"
    echo "  c. Print current plotter parameters"
    echo "  r. Run new plotter process (background)"
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

setup_partition()
{
    echo "Setup partition"
    echo -ne "Enter device name (sdX): "
    read D

    DEVICE=/dev/${D}
    if [ ! -b ${DEVICE} ]; then
        echo "Device ${DEVICE} not found, aborting!"
        return
    fi

    PARTITION=${DEVICE}1
    if [ -b ${PARTITION} ]; then
        echo "Partition ${PARTITION} exists, aborting!"
        return
    fi

    echo -ne "Enter size (TB): "
    read D_SZ

    echo "Lets create a ${D_SZ}.00TB partition ${PARTITION}"
    echo "This action will destroy contents of ${DEVICE}"
    echo "Please make this with *CAUTION*"
    echo "This step is *IRREVERSIBLE*"
    echo "Press y in uppercase"
    echo -ne "if you are sure completely sure what are you doing: "
    read ANS

    if [ $ANS != "Y" ]; then
        echo "Action aborted!"
    else
        echo "Creating partition ${PARTITION} of size ${D_SZ}.00TB"
        parted --script ${DEVICE} \
            mklabel gpt \
            unit TB \
            mkpart primary 0.00TB ${D_SZ}.00TB \
            print
        sleep 1
        echo "Formatting partition ${PARTITION}"
        mkfs.ext4 ${PARTITION}
    fi
}

check_apt_depends()
{
    echo "Checking package dependencies..."
    for DEPEND in ${APT_DEPENDS}
    do
        dpkg -s ${DEPEND} &> /dev/null
        if [ $? -eq 0 ]; then
            echo "Package depend ${DEPEND} is installed"
        else
            sudo apt install ${DEPEND}
        fi
    done
}

chia_activate()
{
    cd ${CHIA_INSTALL_DIR}
    source ./activate
    chia init
}

chia_deactivate()
{
    deactivate
}

print_plot_parameters()
{
    echo "Current values:"
    echo "  K=$PLOT_K"
    echo "  N=$PLOT_N"
    echo "  R=$PLOT_R"
    echo "  B=$PLOT_B"
    echo "  U=$PLOT_U"
    echo "  PLOT_TMP_DRIVE=$PLOT_TMP_DRIVE"
    echo "  PLOT_END_DRIVE=$PLOT_END_DRIVE"
}

set_plot_parameters()
{
    echo -ne "Plot size to create (current K=$PLOT_K): "
    read L_PLOT_K

    echo -ne "Number of plots to create in sequence (current N=$PLOT_N): "
    read L_PLOT_N

    echo -ne "Number of CPU threads allocated for this plotter process (current R=$PLOT_R): "
    read L_PLOT_R

    echo -ne "Amount of RAM in MB to allocate for this plotter (B=$PLOT_B): "
    read L_PLOT_B

    echo -ne "Bucket size (current U=$PLOT_U): "
    read L_PLOT_U

    echo -ne "Current TMP directory (PLOT_TMP_DRIVE=${PLOT_TMP_DRIVE}): "
    read L_PLOT_TMP_DRIVE

    echo -ne "Current END directory (PLOT_END_DRIVE=${PLOT_END_DRIVE}): "
    read L_PLOT_END_DRIVE

    echo -ne "Press y in uppercase to update values: "
    read UPDATE_PARAMS

    if [ "${UPDATE_PARAMS}" == "Y" ]; then
        PLOT_K=${L_PLOT_K}
        PLOT_N=${L_PLOT_N}
        PLOT_R=${L_PLOT_R}
        PLOT_B=${L_PLOT_B}
        PLOT_U=${L_PLOT_U}
        PLOT_TMP_DRIVE=${L_PLOT_TMP_DRIVE%/}
        PLOT_END_DRIVE=${L_PLOT_END_DRIVE%/}
        echo "Plot parameters properly updated"
    fi
}

run_plotter_process()
{
    ERR=0
    if [ ! -d ${PLOT_TMP_DRIVE} ]; then
        echo "Directory ${PLOT_TMP_DRIVE} not found"
        ERR=1
    fi
    mount | grep ${PLOT_TMP_DRIVE}
    if [ $? -ne 0 ]; then
        echo "Directory ${PLOT_TMP_DRIVE} not mounted"
        ERR=1
    fi
    if [ ! -d ${PLOT_END_DRIVE} ]; then
        echo "Directory ${PLOT_END_DRIVE} not found"
        ERR=1
    fi
    mount | grep ${PLOT_END_DRIVE}
    if [ $? -ne 0 ]; then
        echo "Directory ${PLOT_END_DRIVE} not mounted"
        ERR=1
    fi
    if [ $ERR -ne 0 ]; then
        return
    fi

    echo "You are going to run a plotter process with this setup:"
    print_plot_parameters
    echo "Press y in uppercase to run the plotter process: "
    read RUN_PLOTTER

    if [ "${RUN_PLOTTER}" == "Y" ]; then
        export CHIA_INSTALL_DIR
        export PLOT_ID
        export PLOT_K 
        export PLOT_B
        export PLOT_R
        export PLOT_U
        export PLOT_N
        export PLOT_TMP_DRIVE
        export PLOT_END_DRIVE
        export CHIA_LOGS
        chmod 777 ${PLOT_TMP_DRIVE}
        chmod 777 ${PLOT_END_DRIVE}
        screen -d -m -S chia${PLOT_ID} run_plotter.sh
        PLOT_ID=$(($PLOT_ID + 1))
    fi
}

##### MAIN

if [ ! -d ${CHIA_INSTALL_DIR} ]; then
    echo "Install dir not found"
    exit
fi

check_apt_depends
chia_activate

mkdir -p ${CHIA_LOGS}
chmod 777 ${CHIA_LOGS}

while [ 1 ];
do
    show_menu
    echo -ne "Choose an option: "
    read OPT

    case $OPT in
    d) 
        echo "See devices and partitions available"
        cat /proc/partitions
        press_enter
        ;;

    k)
        echo "Set plotter thread parameters"
        set_plot_parameters
        press_enter
        ;;

    c)
        echo "Print current plotter parameters"
        print_plot_parameters
        press_enter
        ;;

    v)
        echo "Show chia version"
        chia version
        press_enter
        ;;

    p) 
        echo "Setup partition"
        setup_partition
        press_enter
        ;;

    r)
        echo "Run plotter process"
        run_plotter_process
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
        echo "Exit from menu"
        chia_deactivate
        exit
        ;;

    *)
        echo "Unknown option"
        press_enter
        ;;
    esac

done

echo 


