#!/bin/bash

#Execulta o script que faz a busca no Zabbix e filtra os IP's do retorno Json com o jq, o SED limpa as aspas do resultado e joga o retorno em um arquivo temporario.
gera=`/.dhost_get.sh | jq ".result[$i].dservices[0].ip" |  sed -e 's/^"//' -e 's/"$//' > /tmp/resultEpmp`

#Passa para a variavel quantos IPs vieram do zabbix
qtd_ips=`echo cat /tmp/resultEpmp  | wc -w`

#Atribui os valores para as variaveis os valores de configuração do cnMaestro a ser inserida nos radios
cambiumADD=https://XXX.XXX.XXX.XXX
cambiumID=YOUR_CAMBIUM_ID
onboardKey=YOUR_ONBOARD_KEY
readCommunity=YOUR_READ_COMMUNITY
writeCommunity=YOUR_WRITE_COMMUNITY

#Inicia o laço de repetição buscando os IPs no arquivo temporario
for ip in $(cat /tmp/resultEpmp); do

#Função para alteração da configuração via SNMP
Injection(){
                #Esta OID ativa o cnMaestro no radio
        snmpset -v2c -c$writeCommunity $ip .1.3.6.1.4.1.17713.21.3.20.1.0 i 1
                #Esta OID seta o endereço do server cnMaestro
        snmpset -v2c -c$writeCommunity $ip .1.3.6.1.4.1.17713.21.3.20.2.0 s $cambiumADD
                #Esta OID seta o cambiumID
        snmpset -v2c -c$writeCommunity $ip .1.3.6.1.4.1.17713.21.3.20.3.0 s $cambiumID
                #Esta OID seta o onboardKey
        snmpset -v2c -c$writeCommunity $ip .1.3.6.1.4.1.17713.21.3.20.4.0 s $onboardKey
                #Esta OID salva a configuração
        snmpset -v2c -c$writeCommunity $ip .1.3.6.1.4.1.17713.21.4.3.0 i 1
                #Esta OID aplica a configuração
        snmpset -v2c -c$writeCommunity $ip .1.3.6.1.4.1.17713.21.4.4.0 i 1
                #Esta OID reinicia o radio, para os FW > 3 não é necessario reinciar o radio
#       snmpset -v2c -c$writeCommunity $ip .1.3.6.1.4.1.17713.21.4.1.0 i 1
}

#Faz uma consulta na OID do endereço do server do cnMaestro e passa o valor para a varivel filtrando por URL com o egrep
testIfCambium=$(snmpget -v2c -c $readCommunity $ip .1.3.6.1.4.1.17713.21.3.20.2.0 | egrep -o '(http|https)://[^/"]+')
                #O IF testa se o valor da consulta anterior é diferente do endereço do server cnMaestro que queremos configurar, caso seja ele roda a função de injeção, caso contrario apenas informa que não rodou.
        if [[  ! -z $testIfCambium && $testIfCambium != $cambiumADD ]]; then
                printf "%s\n" "Injetando $ip ..."
                Injection
        else
                printf "%s\n" "o equipamento com o $ip não é um ePMP ou já está configurado..."
        fi
done
