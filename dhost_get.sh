#!/bin/sh
# Script para listar os hosts descobertos

URL='http://localhost/zabbix/api_jsonrpc.php'
HEADER='Content-Type:application/json'

USER='"USUARIO"'
PASS='"SENHA"'

autenticacao()
{
    JSON='
    {
        "jsonrpc": "2.0",
        "method": "user.login",
        "params": {
            "user": '$USER',
            "password": '$PASS'
        },
        "id": 0
    }
    '
    curl -s -X POST -H "$HEADER" -d "$JSON" "$URL" | cut -d '"' -f8
}
TOKEN=$(autenticacao)

#Altere o "druleids" para o ID da sua descoberta.
dhost_get()
{
    JSON='
    {
        "jsonrpc": "2.0",
        "method": "dhost.get",
        "params": {
            "output": "extend",
            "selectDServices": "extend",
            "druleids": "9", "filter" : { "status" : "0"}
        },
		"auth": "'$TOKEN'",
        "id": 1
    }
    '
    curl -s -X POST -H "$HEADER" -d "$JSON" "$URL" | python -m json.tool
}

dhost_get
