#!/bin/ash

##### Functions #####
Initialise(){
   echo
   lan_ip="$(hostname -i)"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** willisling/alpine container started *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** https://github.com/WillisLing/docker-alpine *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** $(realpath "${0}") date: $(date --reference=$(realpath "${0}") +%Y/%m/%d_%H:%M) *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** $(realpath "${0}") hash: $(md5sum $(realpath "${0}") | awk '{print $1}') *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     $(cat /etc/*-release | grep "^NAME" | sed 's/NAME=//g' | sed 's/"//g') $(cat /etc/*-release | grep "VERSION_ID" | sed 's/VERSION_ID=//g' | sed 's/"//g')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Python version: $(python3 --version | awk '{print $2}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Running user id: $(id --user)"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Running group id: $(id --group)"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local user: ${user:=user}:${user_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local group: ${group:=group}:${group_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Force GID: ${force_gid:=False}"

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     LAN IP Address: ${lan_ip}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Default gateway: $(ip route | grep default | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     DNS server: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')"

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Time zone: ${TZ:=UTC}"
}

CreateGroup(){
   if [ "$(grep -c "^${group}:x:${group_id}:" "/etc/group")" -eq 1 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Group, ${group}:${group_id}, already created"
   else
      if [ "$(grep -c "^${group}:" "/etc/group")" -eq 1 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group name, ${group}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${group_id}:" "/etc/group")" -eq 1 ]; then
         if [ "${force_gid}" = "True" ]; then
            group="$(grep ":x:${group_id}:" /etc/group | awk -F: '{print $1}')"
            echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Group id, ${group_id}, already in use by the group: ${group} - continuing as force_gid variable has been set. Group name to use: ${group}"
         else
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group id, ${group_id}, already in use by the group: ${group} - exiting. If you must to add your user to this pre-existing system group, please set the force_gid variable to True."
            sleep 120
            exit 1
         fi
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Creating group ${group}:${group_id}"
         groupadd --gid "${group_id}" "${group}"
      fi
   fi
}

CreateUser(){
   if [ "$(grep -c "^${user}:x:${user_id}:${group_id}" "/etc/passwd")" -eq 1 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User, ${user}:${user_id}, already created"
   else
      if [ "$(grep -c "^${user}:" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User name, ${user}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${user_id}:$" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User id, ${user_id}, already in use - exiting"
         sleep 120
         exit 1
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Creating user ${user}:${user_id}"
         useradd --shell /bin/ash --gid "${group_id}" --uid "${user_id}" "${user}" --home-dir "/home/${user}"
      fi
   fi
}

SetOwnerAndPermissions(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set owner, ${user}, on script directory, if required"
   find "${script_dir}" ! -user "${user}" -exec chown "${user}" {} +
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set group, ${group}, on script directory, if required"
   find "${script_dir}" ! -group "${group}" -exec chgrp "${group}" {} +

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set ${directory_permissions:=755} permissions on script directories, if required"
   find "${script_dir}" -type d ! -perm "${directory_permissions}" -exec chmod "${directory_permissions}" '{}' +
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set ${file_permissions:=640} permissions on script files, if required"
   find "${script_dir}" -type f ! -perm "${file_permissions}" -exec chmod "${file_permissions}" '{}' +
}

RunScript(){
   local main_script="${script_dir}/main.sh"
   if [ -f "${main_script}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Running ${main_script}"
      su "${user}" -c "${main_script} 2>&1"
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Not found ${main_script}"
   fi
}

##### Script #####
Initialise
CreateGroup
CreateUser
SetOwnerAndPermissions
RunScript

sleep "${sleep_time:=15}"
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** Exiting container *****"
exit 0