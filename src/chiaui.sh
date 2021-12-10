#! /bin/bash
# CRIPTOBADIA SLU
# contacto@criptobadia.es
#
# Chia User interface
# Tool to make your life easier working with Chia coin
# vers: 0.1.1
#

USER=$(whoami)
CHIA_DIR=/home/${USER}/Documentos/chia/src/
CHIA_INSTALL_DIR=/home/${USER}/Documentos/chia-blockchain
WORK_DIR=$(echo ${CHIA_INSTALL_DIR} | sed "s/chia-blockchain//g")
CHIA_LOGS=/home/${USER}/chialogs

# apt-get dependencies
APT_DEPENDS="git vim make gcc parted screen smartmontools lm-sensors htop exfat-utils"

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
    echo "  a. Add plotter directory for farming"
    echo "  c. Print current plotter parameters"
    echo "  d. See devices and partitions available"
    echo "  i. Install systemd services"
    echo "  k. Set plotter parameters"
    echo "  l. Load 24-mnemonic word key"
    echo "  m. Mount partition (/dev/sdX1)"
    echo "  p. Create partition (sdX)"
    echo "  r. Run new plotter process (background)"
    echo "  t. Check CPU temperature"
    echo "  v. Show chia version"
    echo "  1. Start farming"
    echo "  2. Stop farming"
    echo "  3. Upgrade software to latest"
    echo "  4. Generate keys"
    echo "  5. Install software"
    echo "  6. Wallet show"
    echo "  7. Verify plots"
    echo "  8. Verify farmer"
    echo "  9. Verify disk"
    echo "  q. Exit"
    echo "*************************************************"
}

create_partition()
{
    echo -ne "Enter device name (sdX): "
    read D

    DEVICE=/dev/${D}
    if [ ! -b ${DEVICE} ]; then
        echo "Device ${DEVICE} not found, aborting!"
        return
    fi

    EXTRA_PARTITION=""
    if [ ${D:0:4} == "nvme" ]; then
        EXTRA_PARTITION="p"
    fi

    PARTITION=${DEVICE}${EXTRA_PARTITION}1
    if [ ! -b ${PARTITION} ]
    then
        echo -ne "Enter partition size (TB): "
        read D_SZ

        echo "Lets create a ${D_SZ}.00TB partition ${PARTITION}"
        echo "This action will destroy contents of ${DEVICE}"
        echo "Please make this with *CAUTION*"
        echo "This step is *IRREVERSIBLE*"
        echo "If you are completely sure what are you doing..."
        echo -ne "press y in uppercase: "
        read ANS

        if [ $ANS != "Y" ]; then
            echo "Action aborted!"
            return
        else
            echo "Creating partition ${PARTITION} of size ${D_SZ}.00TB"
            sudo parted --script ${DEVICE} \
                mklabel gpt \
                unit TB \
                mkpart primary 0.00TB ${D_SZ}.00TB \
                print
            sleep 1
            echo "Formatting partition ${PARTITION}"
            sudo mkfs.exfat ${PARTITION}
        fi
    fi
}

mount_partition()
{
    echo -ne "Enter partition (sdX1): "
    read PART

    PARTITION=/dev/${PART}
    if [ ! -b ${PARTITION} ]; then
        echo "Partition ${PARTITION} not found, aborting!"
	return
    fi

    # Get the UUID
    UUID=$(sudo blkid ${PARTITION} | cut -f 2 -d " " | sed "s/\"//g" | cut -f 2 -d "=")
    UUID_FOUND=$(cat /etc/fstab | grep ${UUID} | wc -l)
    if [ $UUID_FOUND -gt 0 ]; then
	    echo "Partition $PARTITION is currently mounted, aborting!"
	    return
    fi

    # Setup the mount point
    echo -ne "Set mount point for this partition (i.e. /media/tmp-0X or /media/plot-0X): "
    read MOUNT_POINT
    sudo mkdir -p ${MOUNT_POINT}
    sudo chmod 777 ${MOUNT_POINT}

    # Add /etc/fstab entry
    cat /etc/fstab | grep -v $MOUNT_POINT > /tmp/fstab
    echo "UUID=${UUID} ${MOUNT_POINT} ext4 errors=remount-ro 0 1" >> /tmp/fstab
    sudo mv /tmp/fstab /etc/fstab
    sudo mount -a
}

check_apt_depends()
{
    echo "Checking package dependencies..."
    for DEPEND in ${APT_DEPENDS}
    do
        dpkg -s ${DEPEND} &> /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Package depend ${DEPEND} is installed" &> /dev/null 2>&1
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

verify_disk()
{
    echo -ne "Enter disk name to verify (i.e. sda): "
    read DEVICE
    sudo smartctl -i /dev/$DEVICE
}

upgrade_software_to_latest()
{
    chia stop -d all
    chia_deactivate
    git fetch
    git checkout latest
    git status
    sudo sh install.sh
    . ./activate
    chia_activate
}

install_software()
{
    mkdir -p ${WORK_DIR}
    cd ${WORK_DIR}
    git clone https://github.com/Chia-Network/chia-blockchain.git -b latest --recurse-submodules
    cd ${CHIA_INSTALL_DIR}
    sh install.sh
}

add_24_word_mnemonic_key()
{
    chia keys add
}

install_systemd_services()
{
    sudo mkdir -p /usr/local/chia/

    echo "Install start farming script"
    cp ${CHIA_DIR}/chia-farming-start.sh /tmp/
    sed -i "s|TEMPLATE|${CHIA_INSTALL_DIR}|g" /tmp/chia-farming-start.sh
    sudo mv /tmp/chia-farming-start.sh /usr/local/chia/
    sudo chmod +x /usr/local/chia/chia-farming-start.sh

    echo "Install stop farming script"
    cp ${CHIA_DIR}/chia-farming-stop.sh /tmp/
    sed -i "s|TEMPLATE|${CHIA_INSTALL_DIR}|g" /tmp/chia-farming-stop.sh
    sudo mv /tmp/chia-farming-stop.sh /usr/local/chia/
    sudo chmod +x /usr/local/chia/chia-farming-stop.sh

    echo "Installing systemd service"
    cp ${CHIA_DIR}/chia-farming.service /tmp/
    sed -i "s|WORKDIR|${WORK_DIR}|g" /tmp/chia-farming.service
    sed -i "s|USER|${USER}|g" /tmp/chia-farming.service
    sudo mv /tmp/chia-farming.service /etc/systemd/system/
    #sudo systemctl enable chia-farming.service
    #sudo systemctl start chia-farming.service

    echo "Systemd services properly installed"
}

add_farming_dir()
{
    echo "Enter new directory for farming (/media/plot-0X): "
    read FARMING_DIR
    chia plots add -d ${FARMING_DIR}
}

##### MAIN

if [ ! -d ${CHIA_INSTALL_DIR} ]; then
    echo "Install dir ${CHIA_INSTALL_DIR} not found"
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
    a)
        echo "Add farming directory"
        add_farming_dir
        press_enter
        ;;

    d) 
        echo "See devices and partitions available"
        cat /proc/partitions
        df -h
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

    i)
        echo "Install systemd services"
        install_systemd_services
        press_enter
        ;;

    v)
        echo "Show chia version"
        chia version
        press_enter
        ;;

    p) 
        echo "Create partition"
        create_partition
        press_enter
        ;;

    m)
        echo "Mount partition"
        mount_partition
        press_enter
        ;;	

    r)
        echo "Run plotter process"
        run_plotter_process
        press_enter
        ;;

    l)
        echo "Add 24-mnemonic word key"
        add_24_word_mnemonic_key
        press_enter
        ;;

    t)
        echo "Check CPU temperature"
        sensors
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
        echo "Upgrade software to latest"
        upgrade_software_to_latest
        press_enter
        ;;

    4)
        echo "Generate keys"
        chia init
        chia keys generate
        press_enter
        ;;

    5) 
        echo "Install software"
        install_software
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

    9)
        echo "Verify disk"
        verify_disk
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


