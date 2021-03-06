#!/bin/bash

mkdir -p /local
mkdir -p /workingdir/host{1,2}

ssh-keygen -N '' -f /local/id_rsa
ssh-keygen -N '' -f /workingdir/host1/id_rsa

/bin/cp /local/id_rsa.pub /workingdir/host1/authorized_keys
/bin/cp /workingdir/host1/id_rsa.pub /host1/authorized_keys


echo "root@host1" > /workingdir/host1/sshpiper_upstream
echo "root@host2" > /workingdir/host2/sshpiper_upstream


fail="\033[0;31mFAIL\033[0m"
succ="\033[0;32mSUCC\033[0m"


runtest(){
    casename=$1
    host=$2

    rnd=`head -c 20 /dev/urandom | base64`
    echo $rnd > /names/$host
    rm -f /tmp/$host.stderr
    t=$($3 2>/tmp/$host.stderr)

    if [ "$t" != "$rnd" ];then
        echo -e $casename $fail
    else
        echo -e $casename $succ
    fi

    grep $rnd /workingdir/$host/*

    if [ $? -ne 0 ];then
        echo -e "grep typescript logger" $fail
    fi

    grep "hellopiper" /tmp/$host.stderr

    if [ $? -ne 0 ];then
        echo -e "welcome text" $fail
    fi
}

while true; do

    runtest "host1 with public key:" "host1" "ssh host1@piper -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /local/id_rsa cat /names/host1"
    runtest "host2 with password:" "host2" "sshpass -p root ssh host2@piper -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cat /names/host2"

    sleep 2
done
