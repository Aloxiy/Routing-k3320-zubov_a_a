# Задание

Требуется спроектировать и развернуть IP/MPLS сеть связи для компании «RogaIKopita Games» в среде ContainerLab согласно схеме, представленной на рисунке 1. Необходимо создать все устройства, указанные на схеме, а также корректно соединить их между собой.

<img src="images/task.png" width=600px>

В рамках работы требуется:

* назначить IP-адреса на все интерфейсы;
* настроить протоколы OSPF и MPLS;
* реализовать iBGP с использованием Route Reflector кластера.

Лабораторная работа разделена на две логические части. В первой части настраивается L3VPN, во второй — VPLS. При этом изменять топологию сети не нужно: достаточно демонтировать VRF и на их основе развернуть VPLS.

**Первая часть:**

* настройка iBGP с RR-кластером;
* создание VRF на трёх маршрутизаторах;
* настройка RD и RT на этих маршрутизаторах;
* назначение IP-адресов внутри VRF;
* проверка связности между VRF;
* задание имён устройств, а также изменение логинов и паролей.

**Вторая часть:**

* удаление VRF с трёх маршрутизаторов (либо отвязка их от интерфейсов);
* настройка VPLS на трёх маршрутизаторах;
* конфигурация IP-адресации для PC1, PC2 и PC3 в одной подсети;
* проверка сетевой связности.

# Схема

Схема сети, выполненная в draw.io:

<img src="images/graph-1.png" width=600px>

Схема сети в ContainerLab:

<img src="images/graph-2.png" width=600px>

# YAML-конфигурация

Конфигурация сети аналогична вариантам из предыдущих лабораторных работ: используется 6 маршрутизаторов и 3 компьютера.

Сеть управления: **172.16.16.0/24**.

# Конфигурации

## Маршрутизаторы

### OSPF + MPLS

Настройка OSPF и MPLS заимствована из предыдущей лабораторной работы с учётом изменений в нумерации портов и подключённых сетях, обусловленных новой топологией.

### iBGP с Route Reflector кластером

1. **Выбор ASN**

AS представляет собой совокупность сетей, управляемых одной административной доменной зоной. Поскольку в данной работе используется одна зона, выбирается приватный ASN из диапазона 64512–65534, например 65000.

2. **Настройка iBGP**

Так как вся сеть находится в пределах одной автономной системы, используется iBGP. В конфигурациях всех маршрутизаторов указывается ASN 65000, который также используется для всех BGP-соседей.

Используются следующие разделы конфигурации:

* `/routing bgp instance` — настройка ASN и router-id (используется тот же идентификатор, что и для loopback-интерфейса);
* `/routing bgp peer` — задание параметров соседей (remote-address, remote-as, настройка route-reflector, address-families=l2vpn,vpnv4, привязка к loopback);
* `/routing bgp network` — анонс сети loopback.

3. **Настройка VRF на граничных маршрутизаторах**

На внешних маршрутизаторах выполняется следующая конфигурация:

* `/interface bridge` — создание моста и привязка к нему VRF и IP-адреса;
* `/ip address` — назначение адреса мосту с маской /32;
* `/ip route vrf` — настройка export и import route-targets, route-distinguisher с использованием того же ASN, а также routing-mark;
* `/routing bgp instance vrf` — включение redistribute-connected и указание соответствующего routing-mark.

Важно учитывать нюанс с cluster-id: в данной лабораторной работе все маршрутизаторы подключены только к одному RR. Чтобы маршруты могли корректно распространяться между ними, они должны проходить через два RR. Если RR получает маршрут со своим же cluster-id, он его отбрасывает, поэтому cluster-id необходимо настраивать аккуратно.

4. **Часть 2: настройка VPLS**

В отличие от первой части, здесь важно указать интерфейс, подключённый к компьютеру, в разделе `/mpls ldp interface`.

На всех трёх граничных маршрутизаторах выполняется:

* создание моста (`/interface bridge`);
* добавление порта в мост (`/interface bridge port`), направленного к компьютеру;
* настройка `/interface vpls bgp-vpls` с теми же параметрами, что и у `/ip route vrf`, но вместо routing-mark используется site-id с уникальным значением для каждого маршрутизатора;
* назначение IP-адреса мосту.

Для выдачи IP-адресов компьютерам в одной VPN-сети выбирается один маршрутизатор с DHCP-сервером. В данной работе эту роль выполняет маршрутизатор Санкт-Петербурга.

На всех маршрутизаторах отключается DHCP из первой части, а на SPB-маршрутизаторе создаётся новый пул адресов для VPN-сети и подключается к DHCP-серверу.

## Компьютеры

Как и в предыдущих лабораторных работах, компьютеры получают IP-адреса по DHCP через интерфейс eth1. Во второй части DHCP-сервер расположен на маршрутизаторе Санкт-Петербурга.

# Результаты

Скриншоты собирались поэтапно, по мере выполнения настроек. Например, подтверждение работы iBGP фиксировалось сразу после его настройки, а не после завершения всей конфигурации VPN.

## 1: OSPF

Проверка корректности динамической маршрутизации выполнялась через анализ таблиц маршрутизации.

<img src="images/ospf-1.png" width=600px>
<img src="images/ospf-2.png" width=600px>
<img src="images/ospf-3.png" width=600px>
<img src="images/ospf-4.png" width=600px>
<img src="images/ospf-5.png" width=600px>
<img src="images/ospf-6.png" width=600px>

Как видно, статические маршруты отсутствуют, вся маршрутизация реализована динамически.

## 2: MPLS

<img src="images/mpls-1.png" width=600px>
<img src="images/mpls-2.png" width=600px>
<img src="images/mpls-3.png" width=600px>
<img src="images/mpls-4.png" width=600px>
<img src="images/mpls-5.png" width=600px>
<img src="images/mpls-6.png" width=600px>

## 3: iBGP

В выводе `ip route print where bgp` видно, что BGP-маршруты имеют метрику 200, в то время как для OSPF используется метрика 110. Это означает, что маршруты OSPF имеют больший приоритет.

В выводе `routing bgp peer print status` присутствует флаг **E (Established)**, что указывает на успешное установление всех BGP-сессий и корректность конфигурации.

<img src="images/ibgp-1.png" width=600px>
<img src="images/ibgp-2.png" width=600px>
<img src="images/ibgp-3.png" width=600px>
<img src="images/ibgp-4.png" width=600px>
<img src="images/ibgp-5.png" width=600px>
<img src="images/ibgp-6.png" width=600px>

## 4: VRF

Добавленные маршруты на граничных маршрутизаторах:

<img src="images/vrf1.png" width=600px>
<img src="images/vrf2.png" width=600px>
<img src="images/vrf3.png" width=600px>

Результаты проверки связности между граничными маршрутизаторами:

<img src="images/vrf-ping1.png" width=600px>
<img src="images/vrf-ping2.png" width=600px>
<img src="images/vrf-ping3.png" width=600px>

## Вторая часть: VPLS

Раздача IP-адресов через DHCP-сервер на маршрутизаторе Санкт-Петербурга:

<img src="images/vpls-dhcp.png" width=600px>

Результаты ping между компьютерами:

<img src="images/vpls-ping1.png" width=600px>
<img src="images/vpls-ping2.png" width=600px>
<img src="images/vpls-ping3.png" width=600px>

# Заключение

В ходе лабораторной работы была успешно развернута IP/MPLS сеть связи. В сети настроены протоколы OSPF, MPLS и iBGP с использованием Route Reflector кластера.

В первой части работы реализован L3VPN на базе VRF, во второй части — VPLS. Все устройства были корректно сконфигурированы и соединены, а поставленные задачи выполнены в полном объёме.

Цель лабораторной работы достигнута.

# Источники

1. BGP on a Mikrotik a complete configuration: [https://tech.layer-x.com/bgp-on-mikrotik-a-complete-configuration-guide/](https://tech.layer-x.com/bgp-on-mikrotik-a-complete-configuration-guide/)
2. BGP на Mikrotik: [https://www.cloudhosting.lv/rus/faq/BGP-na-Mikrotik](https://www.cloudhosting.lv/rus/faq/BGP-na-Mikrotik)
3. Route Reflector: [https://linkmeup.gitbook.io/sdsm/8.1.-ibgp/2.-problema-n-kvadrat/0.-route-reflector](https://linkmeup.gitbook.io/sdsm/8.1.-ibgp/2.-problema-n-kvadrat/0.-route-reflector)
4. Mikrotik VTF+NAT: [https://habr.com/ru/articles/262091/](https://habr.com/ru/articles/262091/)
5. Разница между Route Distinguisher и Route Target: [https://habr.com/ru/sandbox/99255/](https://habr.com/ru/sandbox/99255/)
6. Layer-3 MPLS VPN example (пример vrf настройки): [https://web.archive.org/web/20241114213912/https://wiki.mikrotik.com/File:L3vpn.png](https://web.archive.org/web/20241114213912/https://wiki.mikrotik.com/File:L3vpn.png)
7. BGP based VPLS: [https://web.archive.org/web/20241114204010/https://wiki.mikrotik.com/Manual:BGP_based_VPLS](https://web.archive.org/web/20241114204010/https://wiki.mikrotik.com/Manual:BGP_based_VPLS)

Если хочешь, могу сделать версию «пожёстче» под антиплагиат или наоборот упростить язык под отчёт для преподавателя.
