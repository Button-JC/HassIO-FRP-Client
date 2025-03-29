#!/usr/bin/with-contenv bashio
WAIT_PIDS=()

declare serverip
declare serverport
declare authtoken
declare encryption
declare compression

SERVER_IP=$(bashio::config 'serverip')
SERVER_PORT=$(bashio::config 'serverport')
AUTH_TOKEN=$(bashio::config 'token')
LOCAL_PORT=$(bashio::config 'localport')
REMOTE_PORT=$(bashio::config 'remoteport')
ENCRYPTION=$(bashio::config 'encryption')
COMPRESSION=$(bashio::config 'compression')

echo  "********* FRP SERVER CONFIG ********"
echo  "Using Server: ${SERVER_IP}"
echo  "Using Port:   ${SERVER_PORT}"
echo  "Using Token:  ${AUTH_TOKEN}"
echo  "******* HOME ASSISTANT CONFIG ******"
echo  "Using Local Port: ${LOCAL_PORT}"
echo  "Using Remote Port: ${REMOTE_PORT}"
echo  "Using Encryption: ${ENCRYPTION}"
echo  "Using Compression: ${COMPRESSION}"
echo "*************************************"

# Check if /usr/src/frpc.toml exist. If not create with template

if [ ! -f /usr/src/frpc.toml ]; then
    echo "Creating frpc.toml"
    echo "[common]" > /usr/src/frpc.toml
    echo "server_addr = ${SERVER_IP}" >> /usr/src/frpc.toml
    echo "server_port = ${SERVER_PORT}" >> /usr/src/frpc.toml

    # If token is filled then add token authentication
    if [ ! -z "${AUTH_TOKEN}" ]; then
        echo "authentication_method = token" >> /usr/src/frpc.ini
        echo "token = ${AUTH_TOKEN}" >> /usr/src/frpc.toml
    fi

    echo "Adding HA Exposure......."
    echo "" >> /usr/src/frpc.toml
    echo "[hass]" >> /usr/src/frpc.toml
    echo "type = tcp" >> /usr/src/frpc.toml

    # If encryption or/and compression is enabled. add them 
    if [ "${ENCRYPTION}" = "true" ]; then
        echo "use_encryption = true" >> /usr/src/frpc.toml
    fi
    if [ "${COMPRESSION}" = "true" ]; then
        echo "use_compression = true" >> /usr/src/frpc.toml
    fi

    echo "local_ip = 127.0.0.1 " >> /usr/src/frpc.toml
    echo "local_port = ${LOCAL_PORT}" >> /usr/src/frpc.toml
    echo "remote_port = ${REMOTE_PORT}" >> /usr/src/frpc.toml

    echo "Creating frpc.toml done"
fi


# Start FRPC with command: ./frpc -c frpc.toml
echo "Starting FRP client..."

cat /usr/src/frpc.toml

exec ./usr/src/frpc -c /usr/src/frpc.toml

trap "stop_frpc" SIGTERM SIGHUP

# Wait and hold Add-on running
wait "${WAIT_PIDS[@]}"
