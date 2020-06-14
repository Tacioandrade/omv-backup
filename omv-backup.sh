#!/bin/bash
# Criado: Eduardo Jonck - eduardo@eduardojonck.com e  Tácio de Jesus Andrade - tacio@multiti.com.br
# Data: 28-02-2020
# Função: Script que executa o restore do backup do OpenMediaVault em caso de problemas no HD principal
#         ou em caso de troca de placa mãe por defeito! Recomendado se usar RAID, que TODOS os HDs estejam
#         nas mesmas portas SATA que estavam antes para serem reconhecidos pelo sistema com o mesmo
#         nome (sda, sdb, sdc, etc).
#         Para executar o backup, rode o comando omv-backup.sh apenas! Para executar o restore rode o comando
#         omv-backup.sh backup-omv.dominio.local-2020-02-28.tar.gz
# Versão: 1.0


#Salva a conexão dos discos antes de dar problema no servidor
fdisk -l |grep sd  |grep Disk |awk '{print $1,$2}' |cut -d" " -f2 > /etc/openmediavault/status-disk-before

#Consulta a conexao atual dos discos antes do restore do backup
fdisk -l |grep sd  |grep Disk |awk '{print $1,$2}' |cut -d" " -f2 > /etc/openmediavault/status-disk-current

chech_disk=$(diff /etc/openmediavault/status-disk-before /etc/openmediavault/status-disk-current |wc -l)

#Logica para executar ou não o restore
if [ $chech_disk -ne 0 ]; then

#Salva status dos serviços
if [ `ps aux |grep nfs |wc -l` -ne 1 ];then
echo "nfs=enable" > /etc/openmediavault/status-services
else
echo "nfs=disable" > /etc/openmediavault/status-services
fi


if [ `ps aux |grep smbd |wc -l` -ne 1 ];then
echo "smbd=enable" >> /etc/openmediavault/status-services
else
echo "smbd=disable" >> /etc/openmediavault/status-services
fi


if [ `ps aux |grep nmbd |wc -l` -ne 1 ];then
echo "nmbd=enable" >> /etc/openmediavault/status-services
else
echo "nmbd=disable" >> /etc/openmediavault/status-services
fi

if [ `ps aux |grep rsync |wc -l` -ne 1 ];then
echo "rsync=enable" >> /etc/openmediavault/status-services
else
echo "rsync=disable" >> /etc/openmediavault/status-services
fi

if [ `ps aux |grep proftpd |wc -l` -ne 1 ];then
echo "proftpd=enable" >> /etc/openmediavault/status-services
else
echo "proftpd=disable" >> /etc/openmediavault/status-services
fi



#Faz o Backup
tar -cvf backup-`hostname`-`date +%Y-%m-%d-%H%M%S`.tar.gz /etc/openmediavault/config.xml /etc/openmendiavault/status-services /etc/shadow /etc/passwd /etc/ssh/ /etc/group /var/lib/samba/

#Restaura o backup
tar -xf $1 -C /


#Faz o deploy das configurações do config.xml
for run in `omv-mkconf --list`; do
omv-mkconf $run
done



#Habilita os serviços na inicializacao novamente que estavam ativos

if [ `cat /etc/openmediavault/status-services |grep proftpd |cut -d= -f2` = enable ];then
systemctl enable proftpd
fi

if [ `cat /etc/openmediavault/status-services |grep smbd |cut -d= -f2` = enable ];then
systemctl enable smbd
fi

if [ `cat /etc/openmediavault/status-services |grep nmbd |cut -d= -f2` = enable ];then
systemctl enable nmbd
fi

if [ `cat /etc/openmediavault/status-services |grep nfs |cut -d= -f2` = enable ];then
systemctl enable nfs-kernel-server
systemctl enable nfs-server
fi

if [ `cat /etc/openmediavault/status-services |grep rsync |cut -d= -f2` = enable ];then
systemctl enable rsync
fi


#Emite mensagem para que seja feita as configuracoes corretas dos discos antes de continuar
else
echo "Ajuste os discos conforme configuracao abaixo e execute noamente esse script"
cat /etc/openmediavault/status-disk-before
fi

# Reinicia o OMV
#reboot

