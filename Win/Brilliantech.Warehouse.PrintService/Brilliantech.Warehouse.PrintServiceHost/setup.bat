@echo off

:: ��װ���� 
:: ��һ����32λ��ģ��ڶ�����64λ��ģ� ע�⣺ ��64λϵͳ�У�2���������ã���������ѡ��

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set InstallUtil=%windir%\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe  else set InstallUtil=%windir%\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe 

::��������ļ�
set Service=DDNSService.exe

::����˿�
set port=9000

::������ʾ����
set Name="WMS Client Host Service"


if "%1"=="/u" goto Uninstall



  echo ���ڰ�װ���� %Name%

  ::%InstallUtil% %Service%


  echo �������ñ��ض˿�


  netsh http add urlacl url=http://+:%port%/  sddl="D:(A;;GX;;;SY)"

  netsh http add iplisten ipaddress=0.0.0.0:%port%

  echo �������÷���ǽ

  netsh advfirewall firewall add rule name=%Name% dir=in action=allow protocol=TCP localport=%port%


  ::�������񣬿���ע�͵�
  echo ��������

  ::net start %Name%

  echo ��װ��ϣ� ��������� ��Setup.bat�� /u ����ж�ء�

  goto end

:Uninstall

  echo ��ʼж�ط���
  
  echo ����ֹͣ����

  net stop %Name%
  
  echo ����ж�ط��� %Name%

  ::%InstallUtil% %Service% /u


  echo ���������ض˿�����

  netsh http delete urlacl url=http://+:%port%/ 

  netsh http delete iplisten ipaddress=0.0.0.0

  echo �����������ǽ����

  netsh advfirewall firewall delete rule name=%Name% 

 
  echo ж����ϣ� 

  goto end
  

:end
pause


