#!/bin/bash -e


if [ $# -ne 1 ]
then
  echo '  [ERROR] need ww3_bounc input filename in argument [ww3_bounc.inp]'
  exit 1
fi

# link to temporary inp with regtest format
inp="$( cd "$( dirname "$1" )" && pwd )/$(basename $1)"
if [ ! -z $(echo $inp | awk -F'ww3_bounc.inp.' '{print $2}') ] ; then
 new_inp=$(echo $(echo $inp | awk -F'ww3_bounc.inp.' '{print $1}')ww3_bounc_$(echo $inp | awk -F'ww3_bounc.inp.' '{print $2}').inp)
 ln -sfn $inp $new_inp
 old_inp=$inp
 inp=$new_inp
fi

cd $( dirname $inp)
cur_dir="../$(basename $(dirname $inp))"


version=$(bash --version | awk -F' ' '{print $4}')
version4=$(echo $version | cut -d '.' -f1)
echo "bash version : " $version4
if [ "$version4" != "4" ]
then
  echo '  [ERROR] need a version of bash at least 4'
  exit 1
fi


#------------------------------
# clean up inp file from all $ lines

cleaninp="$cur_dir/ww3_bounc_clean.inp"
rm -f $cleaninp

cat $inp | while read line
do

  if [ "$(echo $line | cut -c1)" = "$" ]
  then
    continue
  fi

  cleanline="$(echo $line | awk -F' ' '{print $1}' | cut -d \" -f2  | cut -d \' -f2)"  
  if [ -z "$cleanline" ]
  then
    continue
  fi

  echo "$line" >> $cleaninp

done

#------------------------------
# get all values from clean inp file

readarray -t lines < "$cleaninp"
il=0

mode="$(echo ${lines[$il]} | awk -F' ' '{print $1}' | cut -d \" -f2  | cut -d \' -f2)"
echo $mode

il=$(($il+1))
interp="$(echo ${lines[$il]} | awk -F' ' '{print $1}' | cut -d \" -f2  | cut -d \' -f2)"
echo $interp

il=$(($il+1))
verbose="$(echo ${lines[$il]} | awk -F' ' '{print $1}' | cut -d \" -f2  | cut -d \' -f2)"
echo $verbose

il=$(($il+1))
tmpname="$(echo ${lines[$il]} | awk -F' ' '{print $1}' | cut -d \" -f2  | cut -d \' -f2)"
forispec="$cur_dir/spec.list"
fspec="$cur_dir/spec.list.new"
spec_filename=$forispec
rm -f $fspec
while [ "$tmpname" != "STOPSTRING" ]
do
  echo ${lines[$il]} >> $fspec
  il=$(($il+1))
  tmpname="$(echo ${lines[$il]} | awk -F' ' '{print $1}' | cut -d \" -f2  | cut -d \' -f2)"
done
if [ -f $forispec ]
then
  if [ -z "$(diff $forispec $fspec)" ]
  then
    echo $forispec ' and ' $fspec 'are same.'
    echo 'delete ' $fspec
    rm $fspec
  else
    echo 'diff between :' $forispec ' and new file : ' $fspec
    echo 'inp2nml conversion stopped'
    exit 1
  fi
else
  echo 'mv '$fspec ' to ' $forispec
  mv $fspec $forispec
fi




#------------------------------
# write value in a new nml file

nmlfile=$cur_dir/$(basename $inp .inp).nml

# header
cat > $nmlfile << EOF
! -------------------------------------------------------------------- !
! WAVEWATCH III ww3_bounc.nml - Boundary input post-processing         !
! -------------------------------------------------------------------- !

EOF

# field namelist
cat >> $nmlfile << EOF
! -------------------------------------------------------------------- !
! Define the input boundaries to preprocess via BOUND_NML namelist
!
! * namelist must be terminated with /
! * definitions & defaults:
!     BOUND%MODE                 = 'WRITE'            ! ['WRITE'|'READ']
!     BOUND%INTERP               = 2                  ! interpolation [1(nearest),2(linear)]
!     BOUND%VERBOSE              = 1                  ! [0|1|2]
!     BOUND%FILE                 = 'spec.list'        ! input _spec.nc listing file
! -------------------------------------------------------------------- !
&BOUND_NML
EOF

if [ "${mode}" != "WRITE" ];  then            echo "  BOUND%MODE        =  '${mode}'" >> $nmlfile; fi
if [ "$interp" != "2" ];  then                echo "  BOUND%INTERP      =  $interp" >> $nmlfile; fi
if [ "$verbose" != "1" ];  then               echo "  BOUND%VERBOSE     =  $verbose" >> $nmlfile; fi
if [ "$spec_filename" != "spec.list" ]; then  echo "  BOUND%FILE        =  '$spec_filename'" >> $nmlfile; fi

cat >> $nmlfile << EOF
/


! -------------------------------------------------------------------- !
! WAVEWATCH III - end of namelist                                      !
! -------------------------------------------------------------------- !
EOF
echo "DONE : $( cd "$( dirname "$nmlfile" )" && pwd )/$(basename $nmlfile)"
rm -f $cleaninp
if [ ! -z $(echo $old_inp | awk -F'ww3_bounc.inp.' '{print $2}') ] ; then
  unlink $new_inp
fi
#------------------------------


